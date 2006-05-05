# ヘッダメニューレベルの処理をディスパッチする Controller スーパークラス
class MainController < ApplicationController 
  attr_reader :menues, :title
  layout "main"
  before_filter :authorize
  
  def user
    session[:user]
  end
  
  def initialize(title)
    @title = title
    @menues = []
    @menu_hash = {}
  end

  # 派生クラスで正式なものを定義すること
  def sub_title(action_name)
    action_name
  end

  protected
  
  def menu_caption(key)
    @menu_hash[key]
  end
  
  def add_menu(caption, options, option_key)
    menu = Menu.new(caption, options)
    @menues << menu
    @menu_hash.store(menu.options[option_key], menu.caption)
  end
  

end
