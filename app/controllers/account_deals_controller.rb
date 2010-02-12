class AccountDealsController < ApplicationController 
  layout 'main'
  menu_group "家計簿"
  menu "口座別出納"
  before_filter :check_account
  before_filter :find_account, :except => [:index]
  before_filter :require_mobile, :only => [:balance]
  
  use_calendar :account_deals_path


  deal_actions_for :creditor_general_deal, :debtor_general_deal, :balance_deal,
    :render_options_proc => lambda {|deal_type|
      {:partial => "new_#{deal_type}"}
    },
    :redirect_options_proc => lambda {|deal|
      {:action => :monthly, :year => deal.date.year, :month => deal.date.month}
    }

  def index
    year, month = read_target_date
    redirect_to account_deals_path(:year => year, :month => month, :account_id => current_user.accounts.first.id)
  end
  
  def monthly
    raise InvalidParameterError unless params[:account_id] && params[:year] && params[:month]
    @menu_name = "口座別出納"
    
    @year = params[:year].to_i
    @month = params[:month].to_i
    write_target_date(@year, @month)

    @account = current_user.accounts.find(params[:account_id])
    
    start_date = Date.new(@year, @month, 1)
    end_date = (start_date >> 1) -1
    
    deals = @account.deals.in_a_time_between(start_date, end_date)
    
    @entries = []
    @balance_start = @account.balance_before(start_date)
    balance_estimated = @balance_start
    flow_sum = 0
    for deal in deals do
      for account_entry in deal.entries do
        next unless (account_entry.account.id != @account.id.to_i) || account_entry.balance
        if account_entry.balance
          account_entry.unknown_amount = account_entry.balance - balance_estimated
          balance_estimated = account_entry.balance
          flow_sum -= account_entry.amount unless account_entry.initial_balance?
          # 通常明細
        else
          # 確定のときだけ残高に反映
          if deal.confirmed?
            balance_estimated -= account_entry.amount
            flow_sum -= account_entry.amount
          end
          account_entry.balance_estimated = balance_estimated
          account_entry.flow_sum = flow_sum
        end
        @entries << account_entry
      end
    end
    @balance_end = @entries.size > 0 ? (@entries.last.balance || @entries.last.balance_estimated) : @balance_start 
    @flow_end = flow_sum

    # 登録用
    @deal = Deal::General.new
    @deal.build_simple_entries
  end

  # 携帯専用：残高表示
  def balance
    
  end



  private
  def find_account
    @account = current_user.accounts.find(params[:account_id])
  end

end