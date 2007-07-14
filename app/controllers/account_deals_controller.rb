class AccountDealsController < ApplicationController 
  layout 'main'
  before_filter :check_account, :prepare_date, :prepare_update_account_deals
  
  # 月を選択して口座別出納を表示しなおす  
  def update
    render(:partial => "account_deals", :layout => false)
  end
  
  private

  # 口座別出納　表示準備
  def prepare_update_account_deals
    @accounts = @user.accounts.types_in(:asset)
    
    raise "口座が１つもありません" if @accounts.empty?

    if !params[:account] || !params[:account][:id]
      @account_id = @accounts.first.id
    else
      @account_id = @params[:account][:id].to_i
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
      session[:target_month] = @target_month
    rescue => err
      flash[:notice] = "不正な日付です。 " + @target_month.to_s + err + err.backtrace.to_s
      @account_entries = Array.new
    end
  end
end