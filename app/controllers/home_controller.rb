class HomeController < ApplicationController
  def index
    # TODO:単位をなんとか
    today = Date.today
    @monthly_expense = @user.expense_summary(today.year, today.month)
    @assets_sum, @pure_assets_sum = @user.assets_summary(today.year, today.month)
    @expenses_item = ["支出合計"]
    @assets_item = ["資産合計"]
    @pure_assets_item = ["純資産"]
    @months_for_expenses = ["月"]
    @months_for_assets = ["月"]
    @assets_y_min = @assets_sum
    @assets_y_min = @pure_assets_sum if @pure_assets_sum < @assets_y_min
    @assets_y_max = @assets_sum
    # 前５ヶ月分を計算
    day = today << 5
    while(@expenses_item.size < 6)
      @months_for_expenses << "#{day.month}月"
      @months_for_assets << "#{day.month}月"
      @expenses_item << @user.expense_summary(day.year, day.month)
      assets_sum, pure_assets_sum = @user.assets_summary(day.year, day.month)
      @assets_y_min = assets_sum if assets_sum < @assets_y_min
      @assets_y_min = pure_assets_sum if pure_assets_sum < @assets_y_min
      @assets_y_max = assets_sum if assets_sum > @assets_y_max
      @assets_item << assets_sum
      @pure_assets_item << pure_assets_sum
      day = day >> 1
    end
    @expenses_item << @monthly_expense
    @assets_item << @assets_sum
    @pure_assets_item << @pure_assets_sum
    @months_for_expenses << "#{today.month}月"
    @months_for_assets << "#{today.month}月"
    # TODO: 変化の幅に応じてグラフの詳細を記述する
    margin = (@assets_y_max - @assets_y_min) / 10
    @assets_y_max += margin
    @assets_y_min -= margin

#    today = Date.today
#    redirect_to :controller => 'deals', :year => today.year, :month => today.month
  end
end
