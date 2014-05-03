# -*- encoding : utf-8 -*-
class AccountDealsController < ApplicationController 
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
    redirect_to monthly_account_deals_path(:year => year, :month => month, :account_id => (current_account || current_user.accounts.first).id)
  end
  
  def monthly
    raise InvalidParameterError unless params[:year] && params[:month]
    
    @year = params[:year].to_i
    @month = params[:month].to_i
    write_target_date(@year, @month)
    self.current_account = @account
    @day = read_target_date[2]

    start_date = Date.new(@year, @month, 1)

    @account_entries = AccountEntries.new(@account, start_date, start_date.end_of_month)

    # 登録用
    @deal = Deal::General.new
    @deal.build_simple_entries
  end

  # 携帯専用：残高表示
  def balance
    
  end


end