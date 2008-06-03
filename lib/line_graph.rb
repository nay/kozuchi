# 折れ線グラフ用のデータ
class LineGraph
  attr_accessor :items_values, :item_labels, :x_values, :x_label, :grid, :y_values, :y_label, :min, :max
  
  # [[1, 4, 2], [2, 4, 3], ...]
  def initialize(item_values, item_labels)
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
    if @min >= 10000
      @item_values = item_values.map{|values| values.map{|v| (v.to_f / 10000).round}}
      @max /= 10000
      @min /= 10000
      @y_label = "単位：万円"
    else
      @item_values = item_values.dup
      @y_label = "単位：円"
    end

    # 横軸の目盛りは、minとmaxの間の線が5個以内になるような10の倍数（540 と 780 なら、1→240、10→24、100→2となり 100）を使う
    @grid = 1
    @grid *= 10 until(((@max - @min)/@grid) <= 5)
    @y_values = []

    value = (@min.to_f/@grid).ceil * @grid
    while(value <= @max)
      @y_values << value
      value += @grid
    end
  end

  def y_min
    @min - @grid
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