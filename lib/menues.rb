# メニュー設定
# カスタマイズを許す可能性がある（少なくとも利用モードで表現が変わる）のでユーザー毎にオブジェクトを作れる感じに
# メニュー自体はログインしていなくても利用することを忘れずに
class Menues

  def initialize
    @trees = []
  end
  
  # 現在のurlまたはメニュー名に対して出すべきメニューセットと現在のメニューを返す
  def load(url, name, sender)
    p "url = #{url.inspect}"
    @trees.each{|t| t.each {|menu|
      menu_url = menu.url.kind_of?(Hash) ? sender.url_for(menu.url) : menu.url
      p "menu_url = #{menu_url.inspect}"; return t, menu if menu_url == url || menu.name == name}
    }
    nil
  end
  
  def create_menu_tree(name)
    tree = MenuTree.new
    tree.name = name
    @trees << tree
    yield tree
  end
end
