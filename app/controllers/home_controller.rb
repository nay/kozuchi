class HomeController < ApplicationController
  menu_group "ホーム"
  helper :html5jp_graphs
  
  def index
    prepare_assets_summary
    prepare_expenses_summary
    @IE6 = IE6?
  end

  private
  # 資産概要のデータを準備する
  def prepare_assets_summary
    assets, assets_dates = @user.recent(6) {|user, d| user.assets_summary(d.year, d.month)}
    assets = assets.transpose
    @assets_summary = LineGraph.new(assets, ["資産合計", "純資産"])
    @months_for_assets = ["月"].concat(assets_dates.map{|d| "#{d.month}月"})
  end
  
  def prepare_expenses_summary
    # expenses, expenses_dates = @user.recent(6) {|user, d| user.expenses_summary(d.year, d.month)}
    expenses, expenses_dates = @user.recent(6) {|user, d| user.accounts.expense_sum(d.beginning_of_month, d.end_of_month+1)}
    expenses = [expenses]
    @expenses_summary = LineGraph.new(expenses, ["支出合計"])
    @months_for_expenses = ["月"].concat(expenses_dates.map{|d| "#{d.month}月"})
  end

end
