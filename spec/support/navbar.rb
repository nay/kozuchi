def select_menu(*menus)
  find('body header .navbar').click_link menus.shift
  menus.each do |m|
    click_link m
  end
end
