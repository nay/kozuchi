class MobileDealsController < ApplicationController
  cache_sweeper :export_sweeper, :only => [:create_general_deal]

  before_filter :find_date, :only => [:daily_expenses, :daily_created]

  REDIRECT_OPTIONS_PROC = lambda{|deal|
    {:action => :new_general_deal}
  }
  deal_actions_for :general_deal,
    :redirect_options_proc => REDIRECT_OPTIONS_PROC

  # その日の支出
  def daily_expenses
    @expenses = current_user.accounts.flows(@date, @date + 1, ["accounts.type = ?", "Expense"]) # TODO: Account整理
  end

  # １日の記入履歴の表示
  def daily_created
    @deals = current_user.deals.created_on(@date)
  end

end
