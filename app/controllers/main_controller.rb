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
