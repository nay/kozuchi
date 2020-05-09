# 精算（決済）処理のコントローラ
class SettlementsController < ApplicationController
  cache_sweeper :export_sweeper
  menu_group "精算"
  menu "新しい精算", :only => [:new, :create]

  before_action :find_account,          only: [:new, :create, :update_source, :select_all_deals_in_source, :remove_all_deals_in_source, :destroy_source]
  before_action :read_year_month,       only: [:new, :create, :update_source, :select_all_deals_in_source, :remove_all_deals_in_source, :destroy_source, :summary]
  before_action :set_settlement_source, only: [      :create, :update_source, :select_all_deals_in_source, :remove_all_deals_in_source]
  before_action :find_settlement,       only: [:destroy, :print_form, :submit, :show]

  # 新しい精算口座を作る
  def new
    # 現在記憶している精算があればそれを使う。
    @source = settlement_source(@account, current_year, current_month)

    prepare_for_month_navigator
  end

  # 記憶している作成途中の精算を削除して new へリダイレクトする
  # 記憶がなくても気にしない
  def destroy_source
    clear_settlement_source(@account, current_year, current_month)
    redirect_to url_for
  end
  
  # Ajaxメソッド。口座や日付が変更されたときに呼ばれる
  def update_source
    render :partial => 'target_deals'
  end

  # 編集中の SettlementSource ですべての記入を選択する
  # 新たな記入があったらそれも含めて選択する
  def select_all_deals_in_source
    @source.check_all_deals

    render :partial => 'target_deals'
  end

  # 編集中の SettlementSource ですべての記入の選択を解除する
  def remove_all_deals_in_source
    @source.remove_all_deals

    render :partial => 'target_deals'
  end

  def create
    @settlement = @source.new_settlement
    if @settlement.save
      # 覚えた精算情報を消す
      clear_settlement_source(@account, current_year, current_month)
      redirect_to settlements_path(year: current_year, month: current_month)
    else
      prepare_for_month_navigator
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

  def set_settlement_source
    @source = settlement_source(@account, current_year, current_month)
    store_settlement_source(@account, current_year, current_month, @source)

    @source.attributes = source_params
    @source.deal_ids = {} unless source_params[:deal_ids] # １つも明細が選択されていないと代入が起きないことを回避する
  end

  def store_settlement_source(account, year, month, source)
    account_settlement_sources(account)[year.to_s + month.to_s] = source
  end

  def clear_settlement_source(account, year, month)
    account_settlement_sources(account).delete(year.to_s + month.to_s)
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

  def source_params
    raise InvalidParameterError unless params[:source]
    deal_ids = params[:source][:deal_ids]&.permit!&.keys
    params.require(:source).permit(:name, :description, :target_account_id, deal_ids: deal_ids, paid_on: [:day], start_date: [:year, :month, :day], end_date: [:year, :month, :day])
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
