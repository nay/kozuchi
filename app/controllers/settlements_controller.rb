# -*- encoding : utf-8 -*-
# 精算（決済）処理のコントローラ
class SettlementsController < ApplicationController
  layout 'main'
  cache_sweeper :export_sweeper
  menu_group "精算"
  menu "新しい精算", :only => [:new, :cerate]
  menu "一覧", :only => [:index]
  menu "詳細", :only => [:show]

  before_filter :check_credit_account, :except => [:show, :destroy, :print_form]
  before_filter :load_settlement, :only => [:show, :destroy, :print_form, :submit, :confirm]
  before_filter :new_settlement, :only => [:new, :target_deals, :change_selected_deals]

  # 新しい精算口座を作る
  def new
    @settlement.account = @credit_accounts.detect{|a| a == current_account} || @credit_accounts.first
    @settlement.name = "#{@settlement.account.name}の精算"
  
    # 現在記憶している精算期間があればそれを使う。
    # 精算期間の記憶がなく、現在月の場合は前月にする
    # 初期表示なので、記憶はしない（ほかのページへいってもどっても同じように計算される）
    if @settlement.account == current_account && settlement_start_date && settlement_end_date
      @start_date = settlement_start_date
      @end_date = settlement_end_date
    else
      this_month = Date.new(Date.today.year, Date.today.month, 1)
      @start_date = this_month << 1 # 前月
      @end_date = @start_date.end_of_month
    end
    
    load_deals
    
    # その後の処理のためにセッションに情報を入れておく
    # TODO: current_acocunt導入により、機能がかぶった可能性もあるがいったん保留
    session[:settlement_credit_account_id] = @settlement.account.id
  end
  
  # Ajaxメソッド。口座や日付が変更されたときに呼ばれる
  def target_deals
    raise InvalidParameterError, 'start_date, end_date and settlement are required' unless params[:start_date] && params[:end_date] && params[:settlement]

    begin
      @start_date = to_date(params[:start_date])
      @end_date = to_date(params[:end_date])
    rescue InvalidDateError => e
      render :text => e.message
      return
    end

    @settlement.account = @user.accounts.find(params[:settlement][:account_id])
    # 勘定、精算期間を保存する
    self.current_account = @settlement.account # settlement_xxx_date の代入より先に行う必要がある
    self.settlement_start_date = @start_date
    self.settlement_end_date = @end_date

    @settlement.name = "#{@settlement.account.name}の精算"

    load_deals
    @selected_deals.delete_if{|d| params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]

    render :partial => 'target_deals'
  end

  def create
    @settlement = current_user.settlements.new(params[:settlement])
    @settlement.result_date = to_date(params[:result_date])
    if @settlement.save
      # 覚えた精算期間を消す
      self.settlement_start_date = nil
      self.settlement_end_date = nil
      redirect_to :action => 'index'
    else
      @start_date = to_date(params[:start_date])
      @end_date = to_date(params[:end_date])
      load_deals
      @selected_deals.delete_if{|d| params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]
      render :action => 'new'
    end
  end
  
  def index
    # account_id が指定されていない場合はredirectする
    case params[:account_id]
    when nil
      account_id = if current_account && @credit_accounts.detect{|a| a == current_account}
        current_account.id
      else
        'all'
      end
      redirect_to account_settlements_path(:account_id => account_id)
      return
    when 'all'
      self.current_account = nil
    else
      @account = @credit_accounts.detect{|a| a.id == params[:account_id].to_i}
      raise InvalidParameterError unless @account
      self.current_account = @account
    end

    @settlements = @user.settlements
    @settlements = @settlements.on(@account) if @account
    @settlements = @settlements.includes(:result_entry => :deal).order('deals.date DESC, settlements.id DESC')
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
    unless @settlement
      render :action => 'no_settlement'
      return
    end
  end
  
  # 立替精算依頼書
  def print_form
    if params[:format] == "csv"
      headers["Content-Type"] = 'text/plain; charset=Shift_JIS'
      render :action => 'print_form_csv', :layout => false
      return
    end
    render :layout => false
  end
  
  # 提出状態にする
  def submit
    submitted = @settlement.submit
    
    flash[:notice] = "#{submitted.user.login}さんに提出済としました。"
    redirect_to settlement_path(:id => @settlement.id)
  end
  
  protected
  
  def new_settlement
    @settlement = Settlement.new
    @settlement.user_id = @user.id
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
  
  private
  def load_deals
    @entries = Entry::General.includes(:deal => {:entries => :account}).where("deals.user_id = ? and account_entries.account_id = ? and deals.date >= ? and deals.date <= ? and account_entries.settlement_id is null and account_entries.result_settlement_id is null and account_entries.balance is null", @user.id, @settlement.account.id, @start_date, @end_date).order("deals.date, deals.daily_seq")
    @deals = @entries.map{|e| e.deal}
    @selected_deals = Array.new(@deals)
  end
  
end
 