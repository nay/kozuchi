# -*- encoding : utf-8 -*-
# 精算（決済）処理のコントローラ
class SettlementsController < ApplicationController
  cache_sweeper :export_sweeper
  menu_group "精算"
  menu "新しい精算", :only => [:new, :create]

  before_action :find_account,    only: [:new, :destroy_new, :create, :target_deals]
  before_action :new_settlement,  only: [:new,               :create, :target_deals]
  before_action :read_year_month, only: [:new, :destroy_new, :create, :target_deals, :summary]
  before_action :find_settlement, only: [:show, :destroy, :print_form, :submit]

  # 新しい精算口座を作る
  def new
    # 現在記憶している精算があればそれを使う。
    @source = unsaved_settlement(@account, current_year, current_month)

    # end_date は厳密に、start_date は上まで見る

    @settlement.name                      = @source.name
    @end_date                             = @source.end_date
    @start_date                           = @source.start_date
    @result_date                          = @source.paid_on
    @settlement.result_partner_account_id = @source.target_account_id
    @settlement.description               = @source.description

    load_deals

    prepare_for_month_navigator
  end

  # 記憶している作成途中の精算を削除して new へリダイレクトする
  # 記憶がなくても気にしない
  def destroy_new
    clear_unsaved_settlement(@account, current_year, current_month)
    redirect_to url_for
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

    # 精算の内容を保存する
    # TODO: こういうふうにしたい
    # source = SettlementSource.new(params[:unsaved_settlement])
    # store_unsaved_settlement(source)

    source = SettlementSource.new(account: @account,
                                    start_date: @start_date, end_date: @end_date,
                                    name: params[:settlement][:name],
                                    paid_on: Date.new(params[:result_date][:year].to_i, params[:result_date][:month].to_i, 1) + params[:result_date][:day].to_i - 1,
                                    target_account_id: params[:settlement][:result_partner_account_id],
                                    description: params[:settlement][:description])
    store_unsaved_settlement(@account, current_year, current_month, source)

    @settlement.name = source.name
    @settlement.result_partner_account_id = source.target_account_id
    @settlement.description = source.description
    @result_date = source.paid_on

    load_deals
    @selected_deals.delete_if{|d| params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]

    render :partial => 'target_deals'
  end

  def create
    @settlement.attributes = settlement_params
    @settlement.result_date = to_date(params[:result_date])
    if @settlement.save
      # 覚えた精算情報を消す
      clear_unsaved_settlement(@account, current_year, current_month)
      redirect_to settlements_path(year: current_year, month: current_month)
    else
      # TODO: チェック外していてもついてしまうなど不完全っぽい
      @start_date = to_date(params[:start_date])
      @end_date = to_date(params[:end_date])
      load_deals
      @selected_deals.delete_if{|d| params[:settlement][:deal_ids] && params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]
      prepare_for_month_navigator
      @result_date = @settlement.result_date
      render :action => 'new'
    end
  end

  # 月を指定した概況
  def summary
    @target_date = Date.new(current_year.to_i, current_month.to_i, 1)
    @account = current_user.assets.credit.find(params[:account_id]) if params[:account_id]
    @settlement_summaries = SettlementSummaries.new(current_user, target_date: @target_date, target_account: @account)
    self.menu = @account ? "#{@account.name}の精算" : "すべての精算"
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
    redirect_to settlements_path(year: current_year, month: current_month)
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

  def store_unsaved_settlement(account, year, month, content)
    account_unsaved_settlements(account)[year.to_s + month.to_s] = content
  end

  def clear_unsaved_settlement(account, year, month)
    account_unsaved_settlements(account).delete(year.to_s + month.to_s)
  end

  def new_settlement
    @settlement = Settlement.new
    @settlement.user = current_user
    @settlement.account = @account
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
    ordering = @settlement.account.settlement_order_asc ? 'asc' : 'desc'
    @entries = Entry::General.includes(:deal => {:entries => :account}).where("deals.user_id = ? and account_entries.account_id = ? and deals.date >= ? and deals.date <= ? and account_entries.settlement_id is null and account_entries.result_settlement_id is null and account_entries.balance is null", @user.id, @settlement.account.id, @start_date, @end_date).order("deals.date #{ordering}, deals.daily_seq #{ordering}")
    @deals = @entries.map{|e| e.deal}
    @selected_deals = Array.new(@deals)
  end

  # パラメータの年月から現在年月を更新
  def read_year_month
    write_target_date(params[:year], params[:month])
  end

  # 精算を取得し、精算の年月から現在年月を更新
  def find_settlement
    @settlement = current_user.settlements.find(params[:id])
    write_target_date(@settlement.year, @settlement.month)
  end

end
