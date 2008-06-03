class HomeController < ApplicationController
  def index
    prepare_assets_summary
    
    # TODO:単位をなんとか
    today = Date.today
    @monthly_expense = @user.expense_summary(today.year, today.month)
    @expenses_item = ["支出合計"]
    @months_for_expenses = ["月"]
    # 前５ヶ月分を計算
    day = today << 5
    while(@expenses_item.size < 6)
      @months_for_expenses << "#{day.month}月"
      @expenses_item << @user.expense_summary(day.year, day.month)
      day = day >> 1
    end
    @expenses_item << @monthly_expense
    @months_for_expenses << "#{today.month}月"
  end

  private
  # 資産概要のデータを準備する
  def prepare_assets_summary
    assets, assets_dates = @user.recent(6) {|user, d| user.assets_summary(d.year, d.month)}
    assets = assets.transpose
    @assets_summary = LineGraph.new(assets, ["資産合計", "純資産"])
    # グラフに渡すデータ
    @months_for_assets = ["月"].concat(assets_dates.map{|d| "#{d.month}月"})
  end
end
