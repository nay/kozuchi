require 'time'

# 家計簿機能のコントローラ
class BookController < ApplicationController 
  before_filter :authorize
  layout "userview"
  
  def initialize
    @menu_items = {}
    @menu_items.store("deals", "仕分帳")
  end
  
  def title
    "家計簿"
  end
  
  def name
    "book"
  end
  
  def menu_items
    @menu_items
  end
  
  # 取引の入力を受け付ける
  def save_deal
    deal = Deal.create_simple(
      1, #to do
      Date.parse(params[:new_deal_date]), nil, params[:new_deal_summary],
      params[:new_amount].to_i,
      params[:new_account_minus][:id].to_i,
      params[:new_account_plus][:id].to_i
    )
    flash[:notice] = "記入 #{deal.id} を追加しました。"
    redirect_to(:action => 'deals')
  end
  # 取引の削除を受け付ける
  def delete_deal
    deal = Deal.find(params[:id])
    deal.destroy_deeply
    flash[:notice] = "取引 #{deal.id} を削除しました。"
    redirect_to(:action => 'deals')
  end
  # 月ごとの取引一覧を表示する
  def deals
    @title ="月間取引一覧"
    # 口座一覧を用意する
    @accounts_minus = Account.find(:all,
     :conditions => ["account_type != 2 and user_id = ?", session[:user].id])
    @accounts_plus = Account.find(:all,
     :conditions => ["account_type != 3 and user_id = ?", session[:user].id])
    
    @year = params[:year] || "2006"
    @month = params[:month] || "4"
    @deals = Deal.get_for_month(session[:user].id, @year.to_i, @month.to_i)
  end
  
  
end
