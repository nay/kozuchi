class AccountDealsController < ApplicationController 
  layout 'main'
  menu_group "家計簿"
  menu "口座別出納"

  cache_sweeper :export_sweeper, :only => [:create_creditor_general_deal, :create_debtor_general_deal, :create_balance_deal]

  before_filter :check_account
  before_filter :find_account, :except => [:index]
  before_filter :require_mobile, :only => [:balance]
  

  deal_actions_for :creditor_general_deal, :debtor_general_deal, :balance_deal,
    :ajax => true,
    :render_options_proc => lambda {|deal_type|
      {:partial => "new_#{deal_type}"}
    },
    :redirect_options_proc => lambda {|deal|
      {:action => :monthly, :year => deal.date.year, :month => deal.date.month}
    }

  def index
    year, month = read_target_date
    redirect_to monthly_account_deals_path(:year => year, :month => month, :account_id => current_user.accounts.first.id)
  end
  
  def monthly
    raise InvalidParameterError unless params[:year] && params[:month]
    
    @year = params[:year].to_i
    @month = params[:month].to_i
    write_target_date(@year, @month)
    @day = read_target_date[2]

    start_date = Date.new(@year, @month, 1)
    end_date = (start_date >> 1) -1
    
    deals = @account.deals.in_a_time_between(start_date, end_date)
    
    @entries = []
    @balance_start = @account.balance_before(start_date)
    balance_estimated = @balance_start
    flow_sum = 0
    for deal in deals do
      for account_entry in deal.entries do
        next if account_entry.account.id != @account.id.to_i

        if account_entry.balance?
          account_entry.unknown_amount = account_entry.balance - balance_estimated
          balance_estimated = account_entry.balance
          flow_sum -= account_entry.amount unless account_entry.initial_balance?
        else
          # 確定のときだけ残高に反映
          if deal.confirmed?
            balance_estimated += account_entry.amount
            flow_sum += account_entry.amount
          end
          account_entry.balance_estimated = balance_estimated
          account_entry.flow_sum = flow_sum
          account_entry.partner_account_name = deal.partner_account_name_of(account_entry) # 効率上自分で入れておく
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


end