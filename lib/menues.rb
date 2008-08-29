# メニュー設定
# カスタマイズを許す可能性がある（少なくとも利用モードで表現が変わる）のでユーザー毎にオブジェクトを作れる感じに
# メニュー自体はログインしていなくても利用することを忘れずに
class Menues
  def self.header_menues
    t = MenuTree.new
    t.add_menu('ホーム', :controller => "/home", :action => 'index')
    t.add_menu('家計簿', :controller => "/deals", :action => 'index')
    t.add_menu('精算', :controller => '/settlements', :action => 'new')
    t.add_menu('基本設定', :controller => "/settings/assets", :action => "index")
    t.add_menu('高度な設定', :controller => "/settings/friends", :action => "index")
    t.add_menu('ヘルプ', :controller => "/help", :action => "index")
#      t.add_menu('ログアウト', logout_path)  # TODO
    t.add_menu('ログアウト', :controller => "/sessions", :action => "destroy")
    t
  end
  
  def self.side_menues
    menues = Menues.new

    menues.create_menu_tree('家計簿') {|t|
      t.add_menu('仕訳帳', :controller => '/deals', :action => 'index')
#        t.add_menu('日めくり', :controller => '/daily_booking', :action => 'index')
      t.add_menu('口座別出納', :controller => '/account_deals', :action => 'index')
      t.add_menu('収支表', :controller => '/profit_and_loss', :action => 'index')
      t.add_menu('資産表', :controller => '/assets', :action => 'index')
      t.add_menu('貸借対照表', :controller => '/balance_sheet', :action => 'index')
    }
    
    menues.create_menu_tree('精算') {|t|
      t.add_menu('新しい精算', :controller => '/settlements', :action => 'new')
      t.add_menu('一覧', :controller => '/settlements', :action => 'index')
      t.add_menu('詳細', :controller => '/settlements', :action => 'view')
    }
    
    menues.create_menu_tree('基本設定') {|t|
      t.add_menu('口座', :controller => '/settings/assets', :action => 'index')
      t.add_menu('費目', :controller => '/settings/expenses',:action => 'index')
      t.add_menu('収入内訳', :controller => '/settings/incomes',:action => 'index')
      t.add_menu('プロフィール', :controller => '/users',:action => 'edit')
    }
    
    menues.create_menu_tree('高度な設定') {|t|
      t.add_menu('フレンド', :controller => '/settings/friends',:action => 'index')
      t.add_menu('取引連動',:controller => '/settings/deal_links', :action => 'index')
      t.add_menu('受け皿', :controller => '/settings/partner_account', :action => 'index')
      t.add_menu('カスタマイズ', :controller => '/settings/preferences',:action => 'index')
      t.add_menu('精算ルール', :controller => '/settings/account_rules',:action => 'index')
    }
    
    menues.create_menu_tree('ヘルプ') {|t|
      t.add_menu('小槌の特徴', :controller => '/help', :action => 'index')
      t.add_menu('できること', :controller => '/help', :action => 'functions')
      t.add_menu('FAQ', :controller => '/help', :action => 'faq')
    }
    menues
  end

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
