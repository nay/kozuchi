class DealsController < ApplicationController
  include WithCalendar
  layout 'main'
  before_filter :check_account, :load_target_date
  include ApplicationHelper

  # ----- 入力画面表示系 -----------------------------------------------

  # 指定された行にジャンプするアクション
  def jump
    redirect_to_index(:updated_deal_id => params[:id])
    # todo tab_name は月更新すると不明状態となるので受け渡しても意味がない。hiddenなどで管理可能だが、今後の課題でいいだろう。
#    redirect_to(:action => 'index', :updated_deal_id =>params[:id] )
  end

  # 仕分け帳画面を初期表示するための処理
  # パラメータ：年月、年月日、タブ（明細or残高）、選択行
  def index
    if !params[:year] || !params[:month]
      redirect_to_index
      return 
    end
    self.target_date = {:year => params[:year], :month => params[:month]}
    @target_date = target_date()
    
    # TODO: 整理して共通化
    @updated_deal = params[:updated_deal_id] ? BaseDeal.find(params[:updated_deal_id]) : nil
    if @updated_deal
      @target_month = DateBox.new('year' => @updated_deal.date.year, 'month' => @updated_deal.date.month, 'day' => @updated_deal.date.day) # day for default date
    else
      @target_month = DateBox.new('year' => @target_date[:year], 'month' => @target_date[:month], 'day' => @target_date[:day])
      @date = @target_month
    end
    today = DateBox.today
    @target_month.day = today.day if !@target_month.day && @target_month.year == today.year && @target_month.month == today.month
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
  end

  # 仕分け帳画面部分だけを更新するためのAjax対応処理
  # カレンダーが変更されたとき呼ばれる。URLやメソッド名を変えたい。
#  def update
#    @target_month = DateBox.new(params[:target_month])
#    today = DateBox.today
#    @target_month.day = today.day if !@target_month.day && @target_month.year == today.year && @target_month.month == today.month
#    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
#    self.target_date = params[:target_month].clone
#    render(:partial => "monthly_contents", :layout => false)
#  end

  # ----- 編集実行系 --------------------------------------------------

  # 取引の削除を受け付ける
  def delete_deal
    deal = BaseDeal.find(params[:id])
    deal_info = format_deal(deal)
    deal.destroy
    flash[:notice] = "#{deal_info} を削除しました。"
    redirect_to(:action => 'index')
  end
  
  # 確認処理
  def confirm
    p "confirm"
    deal = BaseDeal.get(params[:id], @user.id)
    p "deal = #{deal}"
    raise "Could not get deal #{params[:id]}" unless deal
    
    deal.confirm
    
    @target_month = DateBox.new('year' => deal.date.year, 'month' => deal.date.month)
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
    @updated_deal = deal
    render(:partial => "deals", :layout => false)
  end

  private
  
  # 仕分け帳　表示準備
  def prepare_update_deals
    # todo preference のロード整備
    @deals_scroll_height = @user.preferences ? @user.preferences.deals_scroll_height : nil
    begin
      @deals = BaseDeal.get_for_month(@user.id, @target_month)
      # TODO: 外にだしたい
      session[:target_month] = @target_month
    rescue Exception
      flash[:notice] = "不正な日付です。 " + @target_month.to_s
      @deals = Array.new
    end
  end

end