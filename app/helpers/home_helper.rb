module HomeHelper

  def large_menu_button_to(name, url, options = {})
    options = {:class => "large_menu_button",
               :onMouseOver => "this.className='large_menu_button_selected';",
               :onMouseOut => "this.className='large_menu_button';"}.merge(options)
    link_to name, url, options
  end
end
