# 精算（決済）処理のコントローラ
class SettlementsController < ApplicationController
  layout 'main'
  before_filter :load_user
  before_filter :check_credit_account, :except => [:view, :delete]
  before_filter :load_settlement, :only => [:view, :delete]
  before_filter :new_settlement, :only => [:new, :change_condition, :change_selected_deals]

  # 新しい精算口座を作る
  def new
    @settlement.account = @credit_accounts.first
  
    @start_date = Date.today << 1
    @start_date = Date.new(@start_date.year, @start_date.month, 1)
    @end_date = @start_date >> 1
    @end_date -= 1
    
    load_deals
    
    # その後の処理のためにセッションに情報を入れておく
    session[:settlement_credit_account_id] = @settlement.account.id
  end
  
  # Ajaxメソッド。口座や日付や選択状態が変更されたときに呼ばれる
  def change_condition
    @start_date = to_date(params[:start_date])
    @end_date = to_date(params[:end_date])
    @settlement.account = @user.accounts.find(params[:settlement][:account_id])

    load_deals
    @selected_deals.delete_if{|d| params["s_#{d.id}".to_sym] != "1"} unless params[:clear_selection]

    render :partial => 'settlement_details'
  end
  
  def create
    @settlement = Settlement.new
    @settlement.user_id = @user.id
    @settlement.attributes = params[:settlement]
    # params から s_ ではじまるkeyをすべてとってIDとして扱う
    selected_deal_ids = params.keys.find_all{|key| key.match(/^s_[0-9]*/)}.map{|key| key[2,key.length-2].to_i}
    
    # 対象取引を追加していく
    # TODO: 未確定などまずいやつは追加を禁止したい
    for deal_id in selected_deal_ids
      entry = AccountEntry.find(:first, :include => :deal, :conditions => ["deals.user_id = ? and deals.id = ? and account_id = ?", @user.id, deal_id, @settlement.account.id])
      p "deal_id = #{deal_id}, entry = #{entry}"
      next unless entry
      @settlement.target_entries << entry
    end
    if @settlement.save
      redirect_to :action => 'index'
    else
      @start_date = to_date(params[:start_date])
      @end_date = to_date(params[:end_date])
      load_deals
      @selected_deals.delete_if{|d| params["s_#{d.id}".to_sym] != "1"} unless params[:clear_selection]
      render :action => 'new'
    end
  end
  
  def index
    @settlements = Settlement.find(:all, :conditions => ["user_id = ?", @user.id], :order => 'id')
  end
  
  # 1件を表示する
  def view
    render :layout => false
  end
  
  # 1件を削除する
  def delete
    @settlement.destroy
    redirect_to :action => 'index'
  end
  
  protected
  
  def new_settlement
    @settlement = Settlement.new
    @settlement.user_id = @user.id
  end
  
  def check_credit_account
    @credit_accounts = @user.accounts.types_in(:credit, :credit_card)
    if @credit_accounts.empty?
      render :action => 'no_credit_account'
      return false
    end
  end
  
  def load_settlement
    @settlement = Settlement.find(:first, :include => [{:target_entries => [:deal, :account]}, {:result_entries => [:deal, :account]}], :conditions => ["settlements.user_id = ? and settlements.id = ?", @user.id, params[:id]])
    return error_not_found unless @settlement
  end
  
  private
  def load_deals
    # TODO: 残高や不明金があると話がややこしい。とりあえず、債権には残高を記入できなかったと思うのでそのまま進める。
    @entries = AccountEntry.find(:all, :include => :deal, :conditions => ["deals.user_id = ? and account_id = ? and deals.date >= ? and deals.date <= ? and settlement_id is null and result_settlement_id is null", @user.id, @settlement.account.id, @start_date, @end_date], :order => "deals.date, deals.daily_seq")
    @deals = @entries.map{|e| e.deal}
    @selected_deals = Array.new(@deals)
  end
  
end
