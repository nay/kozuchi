class AccountDealsController < ApplicationController 
  include WithCalendar
  layout 'main'
  before_filter :check_account, :load_target_date, :load_account
  
  def index
    if !params[:account_id] || !params[:year] || !params[:month]
      redirect_to :action => 'index', :year => @target_date[:year], :month => @target_date[:month], :account_id => @account.id
      return
    end
    @target_month = DateBox.new
    @target_month.year = @target_date[:year]
    @target_month.month = @target_date[:month]
    p @target_month
    p @target_month.start_inclusive
    
    @accounts = @user.accounts.types_in(:asset)
    
    raise "口座が１つもありません" if @accounts.empty?

    if !params[:account_id]
      @account_id = @accounts.first.id
    else
      @account_id = @params[:account_id].to_i
    end
    begin
      deals = BaseDeal.get_for_account(@user.id, @account_id, @target_month)
      @account_entries = Array.new();
      @balance_start = AccountEntry.balance_start(@user.id, @account_id, @target_month.year_i, @target_month.month_i) # これまでの残高
      balance_estimated = @balance_start
      for deal in deals do
        for account_entry in deal.account_entries do
          if (account_entry.account.id != @account_id.to_i) || account_entry.balance
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
    rescue => err
      flash[:notice] = "不正な日付です。 " + @target_month.to_s + err + err.backtrace.to_s
      @account_entries = Array.new
    end
  end
  
  private
  
  # カレンダーから呼ばれる
  # TODO: 統合したいが accountのparamが問題
  def redirect_to_index
    redirect_to :action => 'index', :year => params[:year], :month => params[:month], :account_id => params[:account][:id]
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