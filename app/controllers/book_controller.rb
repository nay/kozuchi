require 'time'

# 家計簿機能のコントローラ
class BookController < ApplicationController 
  before_filter :authorize
  attr_accessor :menu_items, :title, :name
  layout "userview"

  # メニューなどレイアウトに必要な情報を設定する  
  def initialize
    @menu_items = {}
    @menu_items.store("deals", "仕分帳")
    @title = "家計簿"
    @name = "book"
  end

  def select_deal_tab
    prepare_select_deal_tab
    render(:partial => "edit_deal", :layout => false)
  end

  # 仕分け帳画面部分だけを更新するためのAjax対応処理
  def update_deals
    @target_month = DateBox.new(params[:target_month])
    prepare_update_deals
    # ↑帳簿を更新し成功したら月をセッションに格納する
    render(:partial => "deals", :layout => false)
  end

  # 仕分け帳画面を初期表示するための処理
  def deals
    @target_month = session[:target_month]
    @target_month ||= DateBox.this_month
    prepare_select_deal_tab
    prepare_update_deals
  end
  
  # 残高確認記録を登録
  def save_balance
    balance = Balance.new(params[:balance]);
    
  end
  
  # 取引の入力を受け付けて仕分け帳を更新
  def save_deal

    # 月・日に問題がある場合は deal にまかせる
    begin 
      load_date
    rescue Exception
      render(:action => 'deals')
      return
    end
    
    # 金額と日付はJavaScriptではねる
    
    amount = params[:new_amount]
    if (!amount || amount == "")
      redirect_to(:action => 'deals')
      return
    end    

    # 日に問題がある場合はエラー
    date = nil
    begin
      date = get_date
    rescue
      flash[:notice] = "日がおかしいため記入できませんでした。"
      redirect_to(:action => 'deals')
      return
    end

    deal = Deal.create_simple(
      1, #to do
      date, nil, params[:new_deal_summary],
      params[:new_amount].to_i,
      params[:new_account_minus][:id].to_i,
      params[:new_account_plus][:id].to_i
    )
    flash[:notice] = "記入 #{deal.id} を追加しました。"
    redirect_to(:action => 'deals')
  end
  
  # 取引内容の変更フォームを表示する
  def edit_deal
    deal = Deal.find(params[:id])
    # todo
    flash[:notice] = "未実装です。"
    redirect_to(:action => 'deals')
  end
  
  # 取引の削除を受け付ける
  def delete_deal
    deal = Deal.find(params[:id])
    deal.destroy_deeply
    flash[:notice] = "取引 #{deal.id} を削除しました。"
    redirect_to(:action => 'deals')
  end
  
  def select_balance_tab
    @accounts_for_balance = Account.find(:all,
     :conditions => ["account_type == 1 and user_id = ?", session[:user].id])
  
    render(:partial => "edit_balance", :layout => false)
  end


  private
  
  def load_date
    @year = params[:year]
    @month = params[:month]
    @day = params[:day]

    if (!@year || @year=="" || !@month || @month=="")
      @year = session[:year]
      @month = session[:month]
      @day = session[:day]
    end

    if (!@year || @year=="" || !@month || @month=="")
      t = Time.now
      @year = t.year.to_s
      @month = t.month.to_s
      @day = t.day.to_s
      p "load time y#{@year} #{@month} #{@day}"
    end
    
    session[:year] = @year
    session[:month] = @month
    session[:day] = @day
    
    Date.new(@year.to_i, @month.to_i, 1) # exception if illeagl values    
  end
  
  def get_date
    Date.new(@year.to_i, @month.to_i, @day.to_i) # exception if illeagl values
  end  
  
  def prepare_select_deal_tab
    @accounts_minus = Account.find(:all,
     :conditions => ["account_type != 2 and user_id = ?", session[:user].id])
    @accounts_plus = Account.find(:all,
     :conditions => ["account_type != 3 and user_id = ?", session[:user].id])
  end

  def prepare_update_deals
    begin
      @deals = Deal.get_for_month(session[:user].id, @target_month.year_i, @target_month.month_i)
      session[:target_month] = @target_month
    rescue Exception
      flash[:notice] = "不正な日付です。 #{@target_month}"
      @deals = Array.new
    end
  end
  
end
