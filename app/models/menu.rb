# メニュー項目クラス
class Menu
  attr_accessor :caption, :options

  def initialize(caption, options)
    @caption = caption
    @options = options
  end

end