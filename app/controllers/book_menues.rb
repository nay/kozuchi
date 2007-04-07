module BookMenues
  include BaseMenues

  def initialize
    @title = '家計簿'
    @menues = []
    @menu_hash = {}
    add_menu('仕訳帳', {:controller => 'deals', :action => 'index'})
    add_menu('口座別出納', {:controller => 'account_deals', :action => 'index'})
    add_menu('収支表', {:controller => 'profit_and_loss', :action => 'index'})
    add_menu('資産表', {:controller => 'assets', :action => 'index'})
    add_menu('貸借対照表', {:controller => 'balance_sheet', :action => 'index'})
  end

end