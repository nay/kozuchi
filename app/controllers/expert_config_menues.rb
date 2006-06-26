module ExpertConfigMenues
  include BaseMenues

  def initialize
    @title = '高度な設定'
    @menues = []
    @menu_hash = {}
    add_menu('精算ルール', {:controller => 'expert_config',:action => 'account_rules'})
    add_menu('フレンド', {:controller => 'expert_config',:action => 'friends'})
    add_menu('取引連動', {:controller => 'deal_links', :action => 'index'})
    add_menu('受け皿', {:controller => 'partner_account', :action => 'index'})
    add_menu('カスタマイズ', {:controller => 'expert_config',:action => 'preferences'})
  end

end