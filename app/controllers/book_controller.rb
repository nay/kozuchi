require 'time'

# 家計簿機能のコントローラ
class BookController < ApplicationController 
  # 取引の入力を受け付ける
  def save_deal
    deal = Deal.create_simple(
      Time.parse(params[:new_deal_date]), params[:new_deal_summary],
      params[:new_amount].to_i,
      params[:new_account_minus].to_i,
      params[:new_account_plus].to_i
    )
    date = Time.parse(params[:new_deal_date])
    deal = Deal.new(:date => date, :summary => params[:new_deal_summary])
    # add minus
    deal.add_entry(params[:new_account_minus].to_i, params[:new_amount].to_i*(-1))
    deal.add_entry(params[:new_account_plus].to_i, params[:new_amount].to_i)
    deal.save_deeply
 end
  # 取引の削除を受け付ける
  def deleteDeal
  end
  # 月ごとの取引一覧を表示する
  def deals
    # 口座一覧を用意する
    @accounts_minus = Account.find(:all, :conditions => "account_type != 2")
    @accounts_plus = Account.find(:all, :conditions => "account_type != 3")
  end
end
