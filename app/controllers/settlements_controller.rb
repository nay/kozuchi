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
    @settlement.account = @credit_accounts.first
    @settlement.name = "#{@settlement.account.name}の精算"
  
    @start_date = Date.today << 1
    @start_date = Date.new(@start_date.year, @start_date.month, 1)
    @end_date = @start_date >> 1
    @end_date -= 1
    
    load_deals
    
    # その後の処理のためにセッションに情報を入れておく
    session[:settlement_credit_account_id] = @settlement.account.id
  end
  
  # Ajaxメソッド。口座や日付が変更されたときに呼ばれる
  def target_deals
    raise InvalidParameterError, 'start_date, end_date and settlement are required' unless params[:start_date] && params[:end_date] && params[:settlement]
    @start_date = to_date(params[:start_date])
    @end_date = to_date(params[:end_date])
    @settlement.account = @user.accounts.find(params[:settlement][:account_id])
    @settlement.name = "#{@settlement.account.name}の精算"

    load_deals
    @selected_deals.delete_if{|d| params[:settlement][:deal_ids][d.id.to_s] != "1"} unless params[:clear_selection]

    render :partial => 'target_deals'
  end

  def create
    @settlement = current_user.settlements.new(params[:settlement])
    @settlement.result_date = to_date(params[:result_date])
    
    if @settlement.save
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
    @settlements = Settlement.find(:all, :include => {:result_entry => :deal }, :conditions => ["settlements.user_id = ?", @user.id], :order => 'deals.date, settlements.id')
    if @settlements.empty?
      render :action => 'no_settlement'
      return
    end
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
    credit_asset_kinds = asset_kinds{|attributes| attributes[:credit]}.map{|k| k.to_s}
    @credit_accounts = current_user.assets.find(:all, :conditions => ["asset_kind in (?)", credit_asset_kinds])
    if @credit_accounts.empty?
      render :action => 'no_credit_account'
      return false
    end
  end
  
  def load_settlement
    unless params[:id]
      @settlement = Settlement.find(:first, :conditions => ["settlements.user_id = ?", @user.id], :order => "settlements.created_at")
    else
      @settlement = Settlement.find(:first, :conditions => ["settlements.user_id = ? and settlements.id = ?", @user.id, params[:id]])
    end
  end
  
  private
  def load_deals
    @entries = Entry::General.find(:all, :include => {:deal => {:entries => :account}}, :conditions => ["deals.user_id = ? and account_entries.account_id = ? and deals.date >= ? and deals.date <= ? and account_entries.settlement_id is null and account_entries.result_settlement_id is null and account_entries.balance is null", @user.id, @settlement.account.id, @start_date, @end_date], :order => "deals.date, deals.daily_seq")
    @deals = @entries.map{|e| e.deal}
    @selected_deals = Array.new(@deals)
  end
  
end
 