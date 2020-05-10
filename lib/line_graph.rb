# 折れ線グラフ用のデータ
class LineGraph
  attr_accessor :items_values, :item_labels, :x_values, :x_label, :unit, :grid, :y_values, :y_label, :min, :max
  
  # [[1, 4, 2], [2, 4, 3], ...]
  # options
  #   y_label: 縦軸ラベル
  #   max_grid: 縦軸の目盛り。デフォルト5
  def initialize(item_values, item_labels, options = {})
    options = {max_grid: 5}.merge(options)
    @item_labels = item_labels
    @max = nil
    @min = nil
    base_values = item_values.flatten # 計算用
    base_values.each{|v|
      @max = v if @max.nil? || @max < v
      @min = v if @min.nil? || @min > v
    }

    # 値の最小値が10,000以上なら、万単位とする
    # TODO: 設定で変えられるようにする
    # とりあえず動きがないときに微妙なので外す
#    if @min >= 10000
#      @item_values = item_values.map{|values| values.map{|v| (v.to_f / 10000).round}}
#      @max /= 10000
#      @min /= 10000
#      @unit = "万円"
#    else
      @item_values = item_values.dup
      @unit = "円"
#    end
    @y_label = options[:y_label] || "単位：#{@unit}"


    # 横軸の目盛りは、minとmaxの間の線が5（max_grid）個以内になるような10の倍数（540 と 780 なら、1→240、10→24、100→2となり 100）を使う
    @grid = 1
    @grid *= 10 until(((@max - @min)/@grid) <= options[:max_grid])
    @y_values = []

    value = (@min.to_f/@grid).ceil * @grid
    while(value <= @max)
      @y_values << value
      value += @grid
    end
  end

  def y_min
    @min == 0 ? @min : @min - @grid
  end
  
  def y_max
    @max + @grid
  end

  def y
    [@y_label].concat(@y_values || [])
  end
  
  def items
    result = []
    for i in 0...@item_values.size
      result << [@item_labels[i] || ''].concat(@item_values[i])
    end
    result
  end

end
