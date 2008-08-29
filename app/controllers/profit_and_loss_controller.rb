class ProfitAndLossController < ApplicationController 
  include WithCalendar
  layout 'main'
  helper :graph
  before_filter :check_account, :load_target_date, :prepare_update_profit_and_loss

  def index
    if !params[:year] || !params[:month]
      redirect_to_index
      return
    end
    @menu_name = "収支表"
  end

  def update
    render(:partial => "profit_and_loss", :layout => false)
  end
  
  private
  

  def prepare_update_profit_and_loss
    # 費目ごとの合計を得る
    start_inclusive = Date.new(@target_date[:year].to_i, @target_date[:month].to_i, 1)
    end_exclusive = start_inclusive >> 1

    # 全口座のフローを得て、表示用のインスタンス変数に格納していく
    flows = current_user.accounts.flows(start_inclusive, end_exclusive)
    @expense_flows = Flow::PlusList.new
    @income_flows = Flow::MinusList.new
    @asset_plus_flows = Flow::PlusList.new
    @asset_minus_flows = Flow::MinusList.new
    for account in flows
      case account
        when Account::Expense
          @expense_flows << account
        when Account::Income
          @income_flows << account
        else
          if account.flow > 0
            @asset_plus_flows << account
          elsif account.flow < 0
            @asset_minus_flows << account
         end
      end
    end
    # 不明金を得て、収支に加える
    unknowns = current_user.accounts.unknowns(start_inclusive, end_exclusive)
    for account in unknowns
      if account.unknown > 0
        @expense_flows << account
      elsif account.unknown < 0
        @income_flows << account
      end
    end
    @profit = @income_flows.sum - @expense_flows.sum

    session[:target_month] = @target_month
  end
end
