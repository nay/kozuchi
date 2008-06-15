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
  end

  def update
    render(:partial => "profit_and_loss", :layout => false)
  end
  
  private
  

  def prepare_update_profit_and_loss
    # 費目ごとの合計を得る
    start_inclusive = Date.new(@target_date[:year].to_i, @target_date[:month].to_i, 1)
    end_exclusive = start_inclusive >> 1
    
    # 収支・支出の一覧を準備する
    flows = current_user.accounts.flows(start_inclusive, end_exclusive)
    # TODO: AccountSummaryを使わなくて済むようにしたい
    @expenses_summaries = []
    @incomes_summaries = []
    @asset_plus_summaries = []
    @asset_minus_summaries = []
    for account in flows
      case account
        when Account::Expense
          @expenses_summaries << AccountSummary.new(account, account.flow)
        when Account::Income
          @incomes_summaries << AccountSummary.new(account, account.flow*-1)
        else
          if account.flow > 0
            @asset_plus_summaries << AccountSummary.new(account, 0, account.flow)
          elsif account.flow < 0
            @asset_minus_summaries << AccountSummary.new(account, 0, account.flow)
         end
      end
    end
    unknowns = current_user.accounts.unknowns(start_inclusive, end_exclusive)
    for account in unknowns
      if account.unknown > 0
        @expenses_summaries << AccountSummary.new(account, account.unknown)
      elsif account.unknown < 0
        @incomes_summaries << AccountSummary.new(account, account.unknown*-1)
      end
    end
    @expenses_sum = AccountSummary.get_sum(@expenses_summaries)
    @incomes_sum = AccountSummary.get_sum(@incomes_summaries)
    @profit = @incomes_sum - @expenses_sum
    @assets_plus_sum = AccountSummary.get_diff_sum(@asset_plus_summaries)
    @assets_minus_sum = AccountSummary.get_diff_sum(@asset_minus_summaries)

    session[:target_month] = @target_month
    
  end
end
