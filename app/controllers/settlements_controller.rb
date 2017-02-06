# -*- encoding : utf-8 -*-
# 精算（決済）処理のコントローラ
class SettlementsController < ApplicationController
  cache_sweeper :export_sweeper
  menu_group "精算"
  menu "新しい精算", :only => [:new, :cerate]
  menu "精算の概況", :only => [:index]
  menu "精算の詳細", :only => [:show]

  before_action :check_credit_account, :except => [:show, :destroy, :print_form]
  before_action :find_account, only: [:new, :create, :target_deals, :account_settlements]
  before_action :load_settlement, :only => [:show, :destroy, :print_form, :submit, :confirm]
  before_action :new_settlement, :only => [:new, :create, :target_deals]

  # 新しい精算口座を作る
  def new
    @settlement.name = "#{@settlement.account.name}の精算"
  
    # 現在記憶している精算期間があればそれを使う。
    # 精算期間の記憶がなく、現在月の場合は前月にする
    # 初期表示なので、記憶はしない（ほかのページへいってもどっても同じように計算される）
    if account_settlement_term(@account)
      @start_date, @end_date = account_settlement_term(@account)
    else
      this_month = Date.new(Date.today.year, Date.today.month, 1)
      @start_date = this_month << 1 # 前月
      @end_date = @start_date.end_of_month
    end
    
    load_deals

    prepare_for_month_navigator
  end
  
  # Ajaxメソッド。口座や日付が変更されたときに呼ばれる
  def target_deals
    raise InvalidParameterError, 'start_date, end_date and settlement are required' unless params[:start_date] && params[:end_date]

    begin
      @start_date = to_date(params[:start_date])
      @end_date = to_date(params[:end_date])
    rescue InvalidDateError => e
      render :text => e.message
      return
    end

    # 勘定、精算期間を保存する
    store_account_settlement_term(@account, @start_date, @end_date)

    @settlement.name = "#{@settlement.account.name}の精算"

    load_deals
    @selected_deals.delete_if{|d| params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]

    render :partial => 'target_deals'
  end

  def create
    @settlement.attributes = settlement_params
    @settlement.result_date = to_date(params[:result_date])
    if @settlement.save
      # 覚えた精算期間を消す
      clear_account_settlement_term(@account)
      redirect_to :action => 'index'
    else
      @start_date = to_date(params[:start_date])
      @end_date = to_date(params[:end_date])
      load_deals
      @selected_deals.delete_if{|d| params[:settlement][:deal_ids] && params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]
      prepare_for_month_navigator
      render :action => 'new'
    end
  end

  # 概況
  # TDOO: current_account まわりを強引に消したので見直す
  def index
    year, month = params.permit(:year, :month).values
    @target_date = year && month ? Date.new(year.to_i, month.to_i, 1) : Time.zone.today

    prepare_for_summary_months(9, 1, @target_date)
    @previous_target_date = @target_date << 10
    @next_target_date = @target_date >> 10 if @target_date < Time.zone.today.beginning_of_month

    self.menu = "精算情報の概況"
    @summaries = current_user.settlements.includes(:account, :result_entry => :deal).order('deals.date DESC, settlements.id DESC').group_by(&:account)
    @credit_accounts.each do |account|
      @summaries[account] = nil unless @summaries.keys.include?(account)
    end
  end

  # ある勘定の精算一覧を提供する
  def account_settlements
    self.menu = "#{@account.name}の精算一覧"

    @settlements = current_user.settlements.on(@account).includes(:result_entry => :deal).order('deals.date DESC, settlements.id DESC')
    @summaries = {@account => @settlements}
  end
  
  # 1件を削除する
  def destroy
    if @settlement
      name = @settlement.name
      account_name = @settlement.account.name
      @settlement.destroy
      flash[:notice] = "#{account_name}の精算データ「#{name}」を削除しました。"
    else
      flash[:notice] = "精算データを削除できませんでした。"
    end
    redirect_to :action => 'index'
  end

  # TODO: 例外にしたいが、目にしがちな画面なので、エラーページをきれいにしてからのほうがいいかも
  def show
    self.menu = @settlement.name if @settlement.try(:name).present?
    unless @settlement
      render :action => 'no_settlement'
      return
    end
  end
  
  # 立替精算依頼書
  def print_form
    render :layout => false
  end
  
  # 提出状態にする
  def submit
    submitted = @settlement.submit
    
    flash[:notice] = "#{submitted.user.login}さんに提出済としました。"
    redirect_to settlement_path(:id => @settlement.id)
  end
  
  private

  def settlement_terms
    session[:settlement_terms] ||= {}
  end

  def store_account_settlement_term(account, start_date, end_date)
    settlement_terms[account.id] = [start_date, end_date]
  end

  def clear_account_settlement_term(account)
    settlement_terms.delete(account.id)
  end

  def account_settlement_term(account)
    settlement_terms[account.id]
  end
  
  def new_settlement
    @settlement = Settlement.new
    @settlement.user = current_user
    @settlement.account = @account
  end
  
  def check_credit_account
    @credit_accounts = current_user.assets.credit
    if @credit_accounts.empty?
      render :action => 'no_credit_account'
      return false
    end
  end

  # TODO: 名前をかえて関連つかってDRYにしたい
  def load_settlement
    unless params[:id]
      @settlement = Settlement.where("settlements.user_id = ?", @user.id).order("settlements.created_at").first
    else
      @settlement = Settlement.where("settlements.user_id = ? and settlements.id = ?", @user.id, params[:id]).first
    end
  end
  
  # 未精算記入の有無を表示するための月データを作成する
  def prepare_for_month_navigator
    entry_dates = current_user.entries.of(@account.id).where(:settlement_id => nil).where(:result_settlement_id => nil).select("distinct date").order(:date)
    date = Time.zone.today.beginning_of_month
    start_month = date << 24
    end_month = date >> 2
    date = start_month
    @months = []
    while date < end_month
      @months << [date, entry_dates.find_all{|e| e.date.year == date.year && e.date.month == date.month }]
      date = date >> 1
    end
  end

  def prepare_for_summary_months(past = 9, future = 1, target_date = Time.zone.today)
    # 月サマリー用の月情報
    @months = []
    date = start_date = target_date.beginning_of_month << past
    end_date = target_date.beginning_of_month >> future

    while date <= end_date
      @months << date
      date = date >> 1
    end
    @years = @months.group_by(&:year)
  end

  def find_account
    @account = current_user.assets.credit.find(params[:account_id])
  end

  def settlement_params
    result = params.require(:settlement).permit(:name, :description, :result_partner_account_id)
    # TODO: うまい書き方がよくわからない。一括代入しないとおもうのでとりあえず以下は全部許可
    result[:deal_ids] = params[:settlement][:deal_ids].try(:permit!) || {}
    result
  end

  def load_deals
    @entries = Entry::General.includes(:deal => {:entries => :account}).where("deals.user_id = ? and account_entries.account_id = ? and deals.date >= ? and deals.date <= ? and account_entries.settlement_id is null and account_entries.result_settlement_id is null and account_entries.balance is null", @user.id, @settlement.account.id, @start_date, @end_date).order("deals.date, deals.daily_seq")
    @deals = @entries.map{|e| e.deal}
    @selected_deals = Array.new(@deals)
  end
  
end
