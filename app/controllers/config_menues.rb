module ConfigMenues
  include BaseMenues

  def initialize
    @title = '基本設定'
    @menues = []
    @menu_hash = {}
    add_menu('口座', {:controller => 'config', :action => 'assets'})
    add_menu('費目', {:controller => 'config',:action => 'expenses'})
    add_menu('収入内訳', {:controller => 'config',:action => 'incomes'})
    @actions = {1 => 'assets', 2 => 'expenses', 3 => 'incomes'}
    add_menu('カスタマイズ', {:controller => 'config',:action => 'preferences'})
    add_menu('プロフィール', {:controller => 'user',:action => 'edit'})
  end

end