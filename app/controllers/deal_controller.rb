# 1件のDealに対する処理のコントローラ
class DealController < ApplicationController
  include ApplicationHelper

  # 取引入力画面を表示する。以下をデフォルト表示できる。
  # params[:year]:: 年。省略可能。
  # params[:month]:: 月。省略可能。
  # params[:day]:: 日。省略可能。
  # params[:tab_name]]:: deal または　balance # TODO: 変えたい
  # params[:from]:: 移動元勘定のid。
  # params[:to]:: 移動先感情のid。
  def new
    raise "no back to" unless params[:back_to]
    
    @back_to = params[:back_to]
    @updated_deal = params[:updated_deal_id] ? BaseDeal.find(params[:updated_deal_id]) : nil
    if @updated_deal
      @target_month = DateBox.new('year' => @updated_deal.date.year, 'month' => @updated_deal.date.month, 'day' => @updated_deal.date.day) # day for default date
    else
      @target_month = session[:target_month]
      @date = @target_month || DateBox.today
      @target_month ||= DateBox.this_month
    end
    today = DateBox.today
    @target_month.day = today.day if !@target_month.day && @target_month.year == today.year && @target_month.month == today.month
    @tab_name = params[:tab_name] || 'deal'
    
    case @tab_name
      when "deal"
        prepare_select_deal_tab
      else
        prepare_select_balance_tab
    end
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
  end
  
  # params[:back_to][:controller]:: 処理が終わったときに帰る Controller
  # params[:back_to][:action]:: 処理が終わったときに帰る Action
  def save
    raise "no back_to" unless params[:back_to]
    options = params[:back_to]
    begin
      @date = DateBox.new(params[:date])
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
      redirect_to(options)
    end
  end

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

  # 新規編集でサマリが編集されたときにくるAjaxメソッド
  def update_patterns
    summary_key = request.raw_post
    @patterns = Deal.search_by_summary(@user.id, summary_key, 5)
    p "patterns.size = #{@patterns.size}"
    render(:partial => 'patterns')
  end

  # 明細変更状態にするAjaxアクション
  def edit_deal
    @deal = BaseDeal.find(params[:id]) # Deal だとsubordinate がとってこられない。とれてもいいんだけど。
    prepare_select_deal_tab
    render(:partial => "edit_deal", :layout => false)
  end

  # 残高変更状態にするAjaxアクション
  def edit_balance
    @deal = Balance.find(params[:id])
    prepare_select_balance_tab
    render(:partial => "edit_balance", :layout => false)
  end
  
  private

  # 明細登録・変更
  def save_deal
    # 更新のとき
    if params[:deal][:id]
      deal = BaseDeal.get(params[:deal][:id].to_i, @user.id)
      raise "no deal #{params[:deal][:id]}" unless deal
      deal.attributes = params[:deal]
      # 精算ルール以外の理由で未確認のものは確認にする
      # モデルでやると相互作用による更新を見分けるのが大変なのでここでやる
      deal.confirmed = true if !deal.confirmed && !deal.subordinate?
    else
      deal = Deal.new(params[:deal])
      deal.user_id = @user.id
    end
    deal.date = @date.to_date
    deal.save!
    deal
  end

  # 残高確認記録を登録
  def save_balance
    # 更新のとき
    if params[:deal][:id]
      balance = Balance.get(params[:deal][:id].to_i, @user.id)
      raise "no balance #{params[:deal][:id]}" unless balance

      balance.attributes = params[:deal]
    else
      balance = Balance.new(params[:deal])
      balance.user_id = @user.id
    end
      balance.date = @date.to_date
    balance.save!
    balance
  end

  def flash_save_deal(deal, is_new = true)
    @updated_deal = deal
    action_name = is_new ? "追加" : "更新"
    flash[:notice] = "#{format_deal(deal)} を#{action_name}しました。"
  end


  # 記入エリアの準備
  def prepare_select_deal_tab
    @accounts_minus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :income), true
     )
    @accounts_plus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :expense), false
     )
     @deal ||= Deal.new(params[:deal])
    @patterns = [] # 入力支援    
  end
  
  def prepare_select_balance_tab
    @accounts_for_balance = @user.accounts.types_in(:asset)
    @deal ||=  Balance.new
  end

  # 仕分け帳　表示準備
  def prepare_update_deals
    # todo preference のロード整備
    @deals_scroll_height = @user.preferences ? @user.preferences.deals_scroll_height : nil
    begin
      @deals = BaseDeal.get_for_month(@user.id, @target_month)
      session[:target_month] = @target_month
    rescue Exception
      flash[:notice] = "不正な日付です。 " + @target_month.to_s
      @deals = Array.new
    end
  end

end
