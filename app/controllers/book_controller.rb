# 家計簿機能のコントローラ
class BookController < MainController 
  include BookHelper
  
  before_filter :check_account
  
  def check_account
    # 資産口座が1つ以上あり、全部で２つ以上の口座がないとダメ
    if Account.count_in_user(user.id, [Account::ACCOUNT_ASSET])< 1 || Account.count_in_user(user.id) < 2
      render("book/need_accounts")
    end
      
  end
  
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
