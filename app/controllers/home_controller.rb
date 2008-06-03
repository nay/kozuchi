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
    max_assets = nil
    min_assets = nil
    base_assets = assets.flatten # 計算用
    base_assets.each{|a|
      max_assets = a if max_assets.nil? || max_assets < a
      min_assets = a if min_assets.nil? || min_assets > a
    }
    # 値の最小値が10,000以上なら、万単位とする
    # TODO: 設定で変えられるようにする
    if min_assets >= 10000
      assets = assets.map{|asset, pure_asset| [(asset.to_f / 10000).round, (pure_asset.to_f / 10000).round]}
      max_assets /= 10000
      min_assets /= 10000
      @assets_summary_unit = "単位：万円"
    else
      @assets_summary_unit = "単位：円"
    end
    # 横軸の目盛りは、minとmaxの間の線が5個以内になるような10の倍数（540 と 780 なら、1→240、10→24、100→2となり 100）を使う
    assets_grid = 1
    assets_grid *= 10 until(((max_assets - min_assets)/assets_grid) <= 5)
    @assets_grids = [@assets_summary_unit]
    assets_value = (min_assets.to_f/assets_grid).ceil * assets_grid
    while(assets_value <= max_assets)
      @assets_grids << assets_value
      assets_value += assets_grid
    end
    # 今月の情報　　　
    @assets_sum, @pure_assets_sum = assets.last
    # グラフに渡すデータ
    @assets_item = ["資産合計"].concat(assets.map{|a| a[0]})
    @pure_assets_item = ["純資産"].concat(assets.map{|a| a[1]})
    @months_for_assets = ["月"].concat(assets_dates.map{|d| "#{d.month}月"})
    assets_margin = assets_grid
    @assets_y_min = min_assets - assets_margin
    @assets_y_max = max_assets + assets_margin
  end
end
