require 'time'
# 家計簿機能のコントローラ
class BookController < ApplicationController 
  include BookHelper
  before_filter :authorize
  attr_accessor :menu_items, :title, :name
  layout "main"

  # メニューなどレイアウトに必要な情報を設定する  
  def initialize
    @menu_items = {}
    @menu_items.store("deals", "仕分帳")
    @menu_items.store("account_deals", "口座別出納")
    @menu_items.store("profit_and_loss", "収支表")
    @title = "家計簿"
    @name = "book"
  end

  # ----- 入力画面表示系 -----------------------------------------------

  # 明細タブが選択されたときのAjaxアクション
  def select_deal_tab
    prepare_select_deal_tab
    render(:partial => "edit_deal", :layout => false)
  end

  # 残高タブが選択されたときのAjaxアクション
  def select_balance_tab
    prepare_select_balance_tab
    render(:partial => "edit_balance", :layout => false)
  end

  # 明細変更状態にするAjaxアクション
  def edit_deal
    @deal = Deal.find(params[:id])
    prepare_select_deal_tab
    render(:partial => "edit_deal", :layout => false)
  end

  # 残高変更状態にするAjaxアクション
  def edit_balance
    @deal = Deal.find(params[:id])
    prepare_select_balance_tab
    render(:partial => "edit_balance", :layout => false)
  end


  # ----- 編集実行系 --------------------------------------------------

  # タブシート内の「記入」ボタンが押されたときのアクション
  def submit_tab
    @date = DateBox.new(params[:date])
    options = {:action => "deals", :tab_name => params[:tab_name]}
    begin
      if "deal" == params[:tab_name]
        deal = save_deal
        options.store("deal[minus_account_id]", deal.minus_account_id)
        options.store("deal[plus_account_id]", deal.plus_account_id)
      else
        deal = save_balance
        # TODO GET経由で文字列ではいったとき view の collection_select でうまく認識されないから送らない
      end
      session[:target_month] = @date
      flash_save_deal(deal, !params[:deal] || !params[:deal][:id])
      options.store("updated_deal_id", deal.id)
    rescue => err
      flash[:notice] = "エラーが発生したため記入できませんでした。" + err + err.backtrace.to_s
    end
    redirect_to(options)
  end

  # 取引の削除を受け付ける
  def delete_deal
    deal = Deal.find(params[:id])
    deal_info = format_deal(deal)
    deal.destroy_deeply
    flash[:notice] = "#{deal_info} を削除しました。"
    redirect_to(:action => 'deals')
  end

  # ----- 情報表示系 ------------------------------------------------------------

  # 仕分け帳画面を初期表示するための処理
  # パラメータ：年月、年月日、タブ（明細or残高）、選択行
  def deals
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
    @tab_name = params[:tab_name] || 'deal'
    
    case @tab_name
      when "deal"
        prepare_select_deal_tab
      else
        prepare_select_balance_tab
    end
    @updated_deal = params[:updated_deal_id] ? Deal.find(params[:updated_deal_id]) : nil
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
  end

  # 仕分け帳画面部分だけを更新するためのAjax対応処理
  def update_deals
    @target_month = DateBox.new(params[:target_month])
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
    render(:partial => "deals", :layout => false)
  end
  
  
  # 口座別出納
  def account_deals
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
    prepare_update_account_deals  # 帳簿を更新　成功したら月をセッション格納
  end
  
  # 月を選択して口座別出納を表示しなおす  
  def update_account_deals
    @target_month = DateBox.new(params[:target_month])
    prepare_update_account_deals  # 帳簿を更新　成功したら月をセッション格納
    render(:partial => "account_deals", :layout => false)
  end

  # 収支表
  def profit_and_loss
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
    prepare_update_profit_and_loss
  end
  
  def update_profit_and_loss
    @target_month = DateBox.new(params[:target_month])
    prepare_update_profit_and_loss
    render(:partial => "profit_and_loss", :layout => false)
  end
  
  private

  # ----- 入力画面表示系 -----------------------------------------------
  # 記入エリアの準備
  def prepare_select_deal_tab
    @accounts_minus = BookHelper::AccountGroup.groups(
      Account.find_all(session[:user].id, [1,3]), true
     )
    @accounts_plus = BookHelper::AccountGroup.groups(
      Account.find_all(session[:user].id, [1,2]), false
     )
     p params.to_s
     if params[:deal]
       p params[:deal].to_s
       p params[:deal][:minus_account_id].to_s if params[:deal][:minus_account_id]
     end
     @deal ||= Deal.new(params[:deal])
     p "deal.minus_account_id = #{@deal.minus_account_id}"
  end
  
  def prepare_select_balance_tab
    @accounts_for_balance = Account.find_all(session[:user].id, [1])
    @deal ||=  Deal.new
  end

  # ----- 編集実行系 --------------------------------------------------

  # 明細登録・変更
  def save_deal
    # 更新のとき
    if params[:deal][:id]
      Deal.update_simple(params[:deal][:id].to_i,
                    session[:user].id,
                    @date.to_date,
                    params[:deal]
      )
    else
      Deal.create_simple(session[:user].id,
                         @date.to_date,
                         params[:deal],
                         nil
      )
    end
  end

  # 残高確認記録を登録
  def save_balance
    # 更新のとき
    if params[:deal][:id]
      Deal.update_balance(params[:deal][:id].to_i,
                    session[:user].id,
                    @date.to_date,
                    params[:deal]
      )
    else
      Deal.create_balance(session[:user].id,
                         @date.to_date,
                         params[:deal],
                         nil
      )
    end
  end

  def flash_save_deal(deal, is_new = true)
    @updated_deal = deal
    action_name = is_new ? "追加" : "更新"
    flash[:notice] = "#{format_deal(deal)} を#{action_name}しました。"
  end

  # ----- 情報表示系 --------------------------------------------------

  # 仕分け帳　表示準備
  def prepare_update_deals
    begin
      @deals = Deal.get_for_month(session[:user].id, @target_month.year_i, @target_month.month_i)
      session[:target_month] = @target_month
    rescue Exception
      flash[:notice] = "不正な日付です。 " + @target_month.to_s
      @deals = Array.new
    end
  end

  # 口座別出納　表示準備
  def prepare_update_account_deals
  # todo 
    @accounts = Account.find_all(session[:user].id, [1])
    
    if @accounts.size == 0
      raise Exception("口座が１つもありません")
    end
    if !params[:account] || !params[:account][:id]
      @account_id = @accounts.first.id
    else
      @account_id = @params[:account][:id].to_i
    end
    begin
      deals = Deal.get_for_account(session[:user].id, @account_id, @target_month.year_i, @target_month.month_i)
      @account_entries = Array.new();
      @balance_start = AccountEntry.balance_start(session[:user].id, @account_id, @target_month.year_i, @target_month.month_i) # これまでの残高
      balance_estimated = @balance_start
      for deal in deals do
        for account_entry in deal.account_entries do
          if (account_entry.account.id != @account_id.to_i) || account_entry.balance
            if account_entry.balance
              account_entry.unknown_amount = account_entry.balance - balance_estimated
              balance_estimated = account_entry.balance
            else
              balance_estimated -= account_entry.amount
              account_entry.balance_estimated = balance_estimated
            end
            @account_entries << account_entry
          end
        end
      end
      @balance_end = @account_entries.size > 0 ? (@account_entries.last.balance || @account_entries.last.balance_estimated) : @balance_start 
      session[:target_month] = @target_month
    rescue => err
      flash[:notice] = "不正な日付です。 " + @target_month.to_s + err + err.backtrace.to_s
      @account_entries = Array.new
    end
  end
  
  def prepare_update_profit_and_loss
    # 費目ごとの合計を得る
    start_inclusive = Date.new(@target_month.year_i, @target_month.month_i, 1)
    end_exclusive = start_inclusive >> 1
    values = AccountEntry.sum(:amount,
     :group => 'account_id',
     :conditions => ["dl.date >= ? and dl.date < ?", start_inclusive, end_exclusive],
     :joins => "as et inner join deals as dl on dl.id = et.deal_id")
    expense_accounts = Account.find_all(session[:user].id, [2])
    @expenses_summaries = []
    for account in expense_accounts
      @expenses_summaries << AccountSummary.new(account, values[account.id] || 0)
    end
    # 収入項目ごとの合計を得る
    @incomes_summaries = []
    income_accounts = Account.find_all(session[:user].id, [3])
    for account in income_accounts
      @incomes_summaries << AccountSummary.new(account, values[account.id] ? values[account.id]*-1: 0)
    end
    
    # 各資産口座のその月の不明金の合計（プラスかマイナスかはわからない。不明収入と不明支出は相殺する。）を得る
    # TODO 同じ account_summaries でも口座増減と不明金は意味が違い気持ちがわるい
    asset_accounts = Account.find_all(session[:user].id, [1])
    @asset_plus_summaries = []
    @asset_minus_summaries = []
    for account in asset_accounts
      balance_start = AccountEntry.balance_at_the_start_of(session[:user].id, account.id, start_inclusive) # 期首残高
      balance_end = AccountEntry.balance_at_the_start_of(session[:user].id, account.id, end_exclusive) # 期末残高
      diff = balance_end - balance_start
      if diff > 0
        @asset_plus_summaries << AccountSummary.new(account, 0, diff)
      end
      if diff < 0
        @asset_minus_summaries << AccountSummary.new(account, 0, diff)
      end
      # 増減なしなら報告しない

      unknown_amount = balance_end - balance_start - (values[account.id] || 0)
      if unknown_amount > 0
        @incomes_summaries << AccountSummary.new(account, unknown_amount)
      else
        if unknown_amount < 0
          @expenses_summaries << AccountSummary.new(account, unknown_amount.abs)
        end
      end
      # 不明金0なら報告しない
      @expenses_sum = AccountSummary.get_sum(@expenses_summaries)
      @incomes_sum = AccountSummary.get_sum(@incomes_summaries)
      @profit = @incomes_sum - @expenses_sum
      @assets_plus_sum = AccountSummary.get_diff_sum(@asset_plus_summaries)
      @assets_minus_sum = AccountSummary.get_diff_sum(@asset_minus_summaries)

      session[:target_month] = @target_month
    end
    
  end

  
end
