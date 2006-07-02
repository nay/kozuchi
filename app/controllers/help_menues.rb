module HelpMenues
  include BaseMenues

  def initialize
    @title = 'ヘルプ'
    @menues = []
    @menu_hash = {}
    add_menu('小槌の特徴', {:controller => 'help', :action => 'index'})
    add_menu('できること', {:controller => 'help', :action => 'functions'})
    add_menu('FAQ', {:controller => 'help', :action => 'faq'})
  end

end