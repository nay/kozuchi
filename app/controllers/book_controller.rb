# 家計簿機能のコントローラ
class BookController < ApplicationController 
  include BookHelper
  attr_reader :menu_items, :title, :name, :menu_keys
  before_filter :authorize
  layout "main"

  # メニューなどレイアウトに必要な情報を設定する  
  def initialize
    @menu_items = {'deals' => '仕分帳', 'account_deals' => '口座別出納', 'profit_and_loss' => '収支表'}
    @menu_keys = ['deals', 'account_deals', 'profit_and_loss']
    @title = '家計簿'
    @name = 'book'
  end
end
