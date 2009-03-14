class DealsController < ApplicationController
  include WithCalendar
  layout 'main'
  before_filter :require_mobile, :only => :destroy
  before_filter :specify_month, :only => :index
  before_filter :check_account, :load_target_date
  before_filter :find_date, :only => [:expenses, :daily]
  before_filter :find_deal, :only => :destroy
  include ApplicationHelper

  # ----- 入力画面表示系 -----------------------------------------------

  def expenses
    @expenses = current_user.accounts.flows(@date, @date + 1, ["accounts.type = ?", "Expense"]) # TODO: Account整理
  end

  # TODO: 携帯対応でとりあえず入れた。後で調整
  # dealとbalanceを区別したいのでこの命名
  def new_deal
    @deal = Deal.new
    @accounts_minus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :income, :expense), true
     )
    @accounts_plus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :expense, :income), false
     )

  end

  # TODO: モバイル専用
  def create_deal
    @deal = Deal.new(params[:deal])
    @deal.user_id = current_user.id
    @deal.date = Date.today
    if @deal.save
      flash[:notice] = "登録しました。"
      flash[:saved] = true
      redirect_to :action => "new_deal"
    else
    @accounts_minus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :income, :expense), true
     )
    @accounts_plus = ApplicationHelper::AccountGroup.groups(
      @user.accounts.types_in(:asset, :expense, :income), false
     )
      flash[:notice] = "登録に失敗しました。"
      render :action => "new_deal"
    end
  end

  # 指定された行にジャンプするアクション
  def jump
    redirect_to_index(:updated_deal_id => params[:id])
    # todo tab_name は月更新すると不明状態となるので受け渡しても意味がない。hiddenなどで管理可能だが、今後の課題でいいだろう。
#    redirect_to(:action => 'index', :updated_deal_id =>params[:id] )
  end

  # 仕分け帳画面を初期表示するための処理
  # パラメータ：年月、年月日、タブ（明細or残高）、選択行
  def index
    @menu_name = "仕訳帳"
    unless target_date[:year].to_i == params[:year].to_i && target_date[:month].to_i == params[:month].to_i
      self.target_date = {:year => params[:year], :month => params[:month]}
    end
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

  # １日の記入履歴の表示（携帯向けだが制限はしない、本当はidnexで兼ねたい）
  def daily
    @deals = current_user.deals.find(:all, :conditions => ["created_at >= ? and created_at < ?", @date.to_time, (@date + 1).to_time], :order => "created_at desc", :include => {:account_entries => :account})
  end

  # 記入の削除（携帯向け。一般をここに統合するまで制限する）
  def destroy
    @deal.destroy
    flash[:notice] = "削除しました。"
    redirect_to daily_deals_path(:year => @deal.date.year, :month => @deal.date.month, :day => @deal.date.day)
  end

  # キーワードで検索したときに一覧を出す
  def search
    raise InvalidParameterError if params[:keyword].blank?
    @keywords = params[:keyword].split(' ')
    @deals = current_user.deals.including(@keywords)
    @as_action = :index
  end

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
    deal = BaseDeal.get(params[:id], @user.id)
    raise "Could not get deal #{params[:id]}" unless deal
    
    deal.confirm
    
    @target_month = DateBox.new('year' => deal.date.year, 'month' => deal.date.month)
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
    @updated_deal = deal
    render(:partial => "deals", :layout => false)
  end

  private

  def find_deal
    @deal = current_user.deals.find(params[:id])
  end

  def find_date
    raise InvalidParameterError unless @date = extract_date(params)
  end

  def extract_date(params)
    return nil unless params[:year] && params[:month] && params[:day]
    begin
      return Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    rescue => e
      return nil
    end
  end

  
  def redirect_to_index(options = {})
    if options[:updated_deal_id]
      updated_deal = BaseDeal.find(:first, :conditions => ["id = ? and user_id = ?", options[:updated_deal_id], @user.id])
      raise ActiveRecord::RecordNotFound unless updated_deal
      year = updated_deal.year
      month = updated_deal.month
    else
      year = target_date[:year]
      month = target_date[:month]
    end
    options.merge!({:action => 'index', :year => year, :month => month})
    redirect_to options
  end
  
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
  
  def specify_month
    redirect_to_index and return false if !params[:year] || !params[:month]
  end

end