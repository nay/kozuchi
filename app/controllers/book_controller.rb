# 家計簿機能のコントローラ
class BookController < MainController 
  include BookHelper
  
  def sub_title(action_name)
    menu_caption(controller_name)
  end

  # メニューなどレイアウトに必要な情報を設定する  
  def initialize
    super('家計簿')
    add_menu('仕訳帳', {:controller => 'deals', :action => 'index'}, :controller)
    add_menu('口座別出納', {:controller => 'account_deals', :action => 'index'}, :controller)
    add_menu('収支表', {:controller => 'profit_and_loss', :action => 'index'}, :controller)
    add_menu('資産表', {:controller => 'assets', :action => 'index'}, :controller)
  end
end
