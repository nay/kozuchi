module BaseMenues
  attr_reader :menues, :title

  def sub_title(action_name)
    @menu_hash["#{controller_name}#{action_name}"]
  end

  protected
  
  def add_menu(caption, options)
    menu = Menu.new(caption, options)
    @menues << menu
    @menu_hash.store("#{options[:controller]}#{options[:action]}", menu.caption)
  end

end