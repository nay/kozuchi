# 1件のDealに対する処理のコントローラ
class DealController < ApplicationController
  include ApplicationHelper
  
  before_filter :load_target_date
  
  # 取引入力画面を表示する。以下をデフォルト表示できる。
  # params[:tab_name]]:: deal または　balance # TODO: 変えたい
  # params[:back_to][:controller]:: (必須) save 後に処理を戻す先のコントローラ
  # params[:back_to][:action]:: (必須) save 後に処理を戻す先のアクション
  def new
    load_and_assert_back_to

    # deal / balance それぞれのフォーム初期化処理
    @tab_name = params[:tab_name] || 'deal'
    @tab_name == 'deal' ? prepare_select_deal_tab : prepare_select_balance_tab
    render :layout => false
  end
  
  # params[:back_to][:controller]:: 処理が終わったときに帰る Controller
  # params[:back_to][:action]:: 処理が終わったときに帰る Action
  def save
    load_and_assert_back_to
    options = @back_to
    begin
      if "deal" == params[:tab_name]
        deal = save_deal
        options.store("deal[minus_account_id]", deal.minus_account_id)
        options.store("deal[plus_account_id]", deal.plus_account_id)
      else
        deal = save_balance
        # TODO GET経由で文字列ではいったとき view の collection_select でうまく認識されないから送らない
      end
      session[:target_month] = deal.date
      self.target_date = deal.date
      flash_save_deal(deal, !params[:deal] || !params[:deal][:id])
      options.store("updated_deal_id", deal.id)
      options[:year] = deal.year
      options[:month] = deal.month
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
    summary_key = params[:keyword]
    @patterns = Deal.search_by_summary(@user.id, summary_key, 5)
    render(:partial => 'patterns')
  end

  # 明細変更状態にするAjaxアクション
  def edit_deal
    load_and_assert_back_to
    @deal = BaseDeal.find(params[:id]) # Deal だとsubordinate がとってこられない。とれてもいいんだけど。
    @tab_name = 'deal'
    prepare_select_deal_tab
    render(:action => "new", :layout => false)
  end

  # 残高変更状態にするAjaxアクション
  def edit_balance
    load_and_assert_back_to  
    @deal = Balance.find(params[:id])
    @tab_name = 'balance'
    prepare_select_balance_tab
    render(:action => "new", :layout => false)
  end
  
  private
  def load_and_assert_back_to
    raise "back_to is not defined properly." unless params[:back_to] && params[:back_to][:controller] && params[:back_to][:action]
    @back_to = params[:back_to].clone
  end
  

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
      @user.accounts.types_in(:asset, :income, :expense), true
     )
    @accounts_plus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :expense, :income), false
     )
    unless @deal
      @deal = Deal.new(params[:deal])
      @deal.date = target_date # セッションから判断した日付を入れる
    end

    @patterns = [] # 入力支援    
  end
  
  def prepare_select_balance_tab
    @accounts_for_balance = @user.accounts.types_in(:asset)
    @deal ||=  Balance.new(:account_id => @accounts_for_balance.id)
  end

end
