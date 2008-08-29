class MenuTree
  attr_accessor :name
  def initialize
    @array = []
  end
  def add_menu(name, url)
    menu = Menu.new
    menu.name = name
    menu.url = url
    @array << menu
  end
  def each(&block)
    @array.each &block
  end
  def last
    @array.last
  end
end
