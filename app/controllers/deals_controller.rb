class DealsController < BookController 

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
    @deal = Balance.find(params[:id])
    prepare_select_balance_tab
    render(:partial => "edit_balance", :layout => false)
  end

  # ----- 編集実行系 --------------------------------------------------

  # タブシート内の「記入」ボタンが押されたときのアクション
  def submit_tab
    @date = DateBox.new(params[:date])
    options = {:action => 'index', :tab_name => params[:tab_name]}
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
    deal = BaseDeal.find(params[:id])
    deal_info = format_deal(deal)
    deal.destroy
#    deal.destroy_deeply
    flash[:notice] = "#{deal_info} を削除しました。"
    redirect_to(:action => 'index')
  end


  # 仕分け帳画面を初期表示するための処理
  # パラメータ：年月、年月日、タブ（明細or残高）、選択行
  def index
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
    @updated_deal = params[:updated_deal_id] ? BaseDeal.find(params[:updated_deal_id]) : nil
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
  end

  # 仕分け帳画面部分だけを更新するためのAjax対応処理
  def update
    @target_month = DateBox.new(params[:target_month])
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
    render(:partial => "deals", :layout => false)
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
    @deal ||=  Balance.new
  end

  # ----- 編集実行系 --------------------------------------------------

  # 明細登録・変更
  def save_deal
    # 更新のとき
    if params[:deal][:id]
      deal = Deal.get(params[:deal][:id].to_i, user.id)
      raise "no deal #{params[:deal][:id]}" unless deal
      
      deal.attributes = params[:deal]
      
    else
      deal = Deal.new(params[:deal])
      deal.user_id = user.id
    end
    deal.date = @date.to_date
    deal.save!
    deal
  end

  # 残高確認記録を登録
  def save_balance
    # 更新のとき
    if params[:deal][:id]
      balance = Balance.get(params[:deal][:id].to_i, user.id)
      raise "no balance #{params[:deal][:id]}" unless balance

      balance.attributes = params[:deal]
    else
      balance = Balance.new(params[:deal])
      balance.user_id = user.id
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

  
  # 仕分け帳　表示準備
  def prepare_update_deals
    begin
      @deals = BaseDeal.get_for_month(session[:user].id, @target_month)
      session[:target_month] = @target_month
    rescue Exception
      flash[:notice] = "不正な日付です。 " + @target_month.to_s
      @deals = Array.new
    end
  end

end