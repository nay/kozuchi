# TODO: すべてのAccountに適用したい
class AccountDealsController < ApplicationController 
  include WithCalendar
  layout 'main'
  before_filter :check_account, :load_target_date
  
  def index
    redirect_to account_deals_path(:year => @target_date[:year], :month => @target_date[:month], :account_id => current_user.accounts.first.id)
  end
  
  def monthly
    raise InvalidParameterError unless params[:account_id] && params[:year] && params[:month]
    @menu_name = "口座別出納"
    
    @year = params[:year].to_i
    @month = params[:month].to_i
    # TODO: ↑共通化
    
    @target_month = DateBox.new
    @target_month.year = @target_date[:year]
    @target_month.month = @target_date[:month]

    @account = current_user.accounts.find(params[:account_id])
    
    # deals = BaseDeal.get_for_account(@user.id, @account.id, @target_month)
    start_date = Date.new(@year, @month, 1)
    end_date = (start_date >> 1) -1
    
    deals = @account.deals.in_a_time_between(start_date, end_date)
    
    @account_entries = []
    @balance_start = @account.balance_before(start_date)
    balance_estimated = @balance_start
    for deal in deals do
      for account_entry in deal.account_entries do
        if (account_entry.account.id != @account.id.to_i) || account_entry.balance
          if account_entry.balance
            account_entry.unknown_amount = account_entry.balance - balance_estimated
            balance_estimated = account_entry.balance
          # 通常明細
          else
            # 確定のときだけ残高に反映
            if deal.confirmed
              balance_estimated -= account_entry.amount
            end
            account_entry.balance_estimated = balance_estimated
          end
          @account_entries << account_entry
        end
      end
    end
    @balance_end = @account_entries.size > 0 ? (@account_entries.last.balance || @account_entries.last.balance_estimated) : @balance_start 
  end
  
  private
  
  # カレンダーから呼ばれる
  # TODO: 統合したいが accountのparamが問題
  def redirect_to_index
    redirect_to account_deals_path(:year => params[:year], :month => params[:month], :account_id => params[:account_id])
  end

  def load_account
    if params[:account_id]
      @account = @user.accounts.find(params[:account_id])
      # なかったらエラー
    else
      @account = @user.accounts.first
    end
  end


end