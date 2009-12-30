class AccountDealsController < ApplicationController 
  layout 'main'
  menu_group "家計簿"
  menu "口座別出納"
  before_filter :check_account
  before_filter :find_account, :except => [:index]
  before_filter :require_mobile, :only => [:balance]
  
  use_calendar :account_deals_path

  # 更新系
  def create_creditor_general_deal
    @deal = @user.general_deals.new(params[:deal])

    if @deal.save
      flash[:notice] = "#{@deal.human_name} を追加しました。" # TODO: 他コントーラとDRYに
      render :update do |page|
        page.redirect_to :action => :monthly, :year => @deal.date.year, :month => @deal.date.month
      end
    else
      render :update do |page|
        page[:deal_forms].replace_html :partial => 'new_creditor_general_deal'
      end
    end
  end

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
          if deal.confirmed
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
    @deal.debtor_entries.build
    @deal.creditor_entries.build
  end

  # 携帯専用：残高表示
  def balance
    
  end


  def new_balance_deal
    render :partial => 'new_balance_deal'
  end


  private
  def find_account
    @account = current_user.accounts.find(params[:account_id])
  end

end