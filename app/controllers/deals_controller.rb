class DealsController < ApplicationController
  include WithCalendar
  layout 'main'
  cache_sweeper :export_sweeper, :only => [:create_deal, :destroy, :confirm] 
  menu_group "家計簿"
  menu "仕訳帳"
  before_filter :specify_month, :only => :index
  before_filter :check_account, :load_target_date
  before_filter :find_date, :only => [:expenses, :daily]
  before_filter :find_deal, :only => [:edit, :update, :destroy]
  include ApplicationHelper

  # ----- 入力画面表示系 -----------------------------------------------

  def expenses
    @expenses = current_user.accounts.flows(@date, @date + 1, ["accounts.type = ?", "Expense"]) # TODO: Account整理
  end

  # TODO: 携帯対応でとりあえず入れた。後で調整
  # dealとbalanceを区別したいのでこの命名
  def new_deal
    @deal = Deal::General.new
    @accounts_minus = ApplicationHelper::AccountGroup.groups(
      @user.accounts, true
    )
    @accounts_plus = ApplicationHelper::AccountGroup.groups(
      @user.accounts, false
    )
    #     text = render_to_string :template => "deals/test.html.erb"
    #     p text
    #     render :text => "aaa"
  end

  # TODO: モバイル専用
  def create_deal
    @deal = Deal::General.new(params[:deal])
    @deal.user_id = current_user.id
    @deal.date = Date.today
    if @deal.save
      flash[:notice] = "登録しました。"
      flash[:saved] = true
      redirect_to :action => "new_deal"
    else
      @accounts_minus = ApplicationHelper::AccountGroup.groups(
        @user.accounts, true
      )
      @accounts_plus = ApplicationHelper::AccountGroup.groups(
        @user.accounts, false
      )
      flash[:notice] = "登録に失敗しました。"
      render :action => "new_deal"
    end
  end

  RENDER_OPTIONS_PROC = lambda {|deal_type|
    {:partial => "#{deal_type}_form"}
  }

  REDIRECT_OPTIONS_PROC = lambda{|deal|
    {:action => :index, :year => deal.date.year, :month => deal.date.month, :updated_deal_id => deal.id}
  }
  deal_actions_for :general_deal, :complex_deal, :balance_deal,
    :render_options_proc => RENDER_OPTIONS_PROC,
    :redirect_options_proc => REDIRECT_OPTIONS_PROC

  # 変更フォームを表示するAjaxアクション
  def edit
    if @deal.kind_of?(Deal::General) && (params[:complex] == 'true' || !@deal.simple?)
      @deal.fill_complex_entries
    end
    render :partial => 'edit' # TODO: partialやめる
  end

  def update
    deal_attributes = params[:deal].dup
    # TODO: もう少しマシにしたいがとりあえず動かすために入れる
    # creditor側の数字しか入ってこない場合はもう片側を補完する
    deal_attributes[:creditor_entries_attributes]['0'][:amount] = deal_attributes[:debtor_entries_attributes]['0'][:amount].to_i * -1 unless deal_attributes[:creditor_entries_attributes]['0'][:amount]

    @deal.attributes = deal_attributes

    @deal.confirmed = true

    deal_type = @deal.kind_of?(Deal::Balance) ? 'balance_deal' : 'general_deal'
    if @deal.save
      flash[:notice] = "#{@deal.human_name} を更新しました。" # TODO: 他コントーラとDRYに
      flash[:"#{controller_name}_deal_type"] = deal_type
      flash[:day] = @deal.date.day
      render :update do |page|
        page.redirect_to REDIRECT_OPTIONS_PROC.call(@deal)
      end
    else
      unless @deal.simple?
        @deal.fill_complex_entries
      end
      render :update do |page|
        page[:deal_editor].replace_html :partial => 'edit'
      end
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
    @updated_deal = params[:updated_deal_id] ? Deal::Base.find(params[:updated_deal_id]) : nil
    if @updated_deal
      @target_month = DateBox.new('year' => @updated_deal.date.year, 'month' => @updated_deal.date.month, 'day' => @updated_deal.date.day) # day for default date
    else
      @target_month = DateBox.new('year' => @target_date[:year], 'month' => @target_date[:month], 'day' => @target_date[:day])
      @date = @target_month
    end
    today = DateBox.today
    @target_month.day = today.day if !@target_month.day && @target_month.year == today.year && @target_month.month == today.month
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納

    # 旧 deal#new でやっていたrender_component内の準備を以下にとりあえず移動
    @back_to = {:controller => 'deals', :action => 'index'}

    # deal / balance それぞれのフォーム初期化処理
    @tab_name = params[:tab_name] || 'deal'
    @tab_name == 'deal' ? prepare_select_deal_tab : prepare_select_balance_tab
    #    render :layout => false

    # 登録用
    @deal = Deal::General.new
    @deal.build_simple_entries

  end

  # １日の記入履歴の表示（携帯向けだが制限はしない、本当はindexで兼ねたい）
  def daily
    @deals = current_user.deals.created_on(@date)
  end

  # 記入の削除
  def destroy
    @deal.destroy
    flash[:notice] = "#{@deal.human_name} を削除しました。"
    if request.mobile?
      redirect_to daily_deals_path(:year => @deal.date.year, :month => @deal.date.month, :day => @deal.date.day)
    else
      redirect_to(:action => 'index')
    end
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
#  def delete_deal
#    deal = Deal::Base.find(params[:id])
#    deal.destroy
#    flash[:notice] = "#{deal.human_name} を削除しました。"
#    redirect_to(:action => 'index')
#  end
  
  # 確認処理
  def confirm
    deal = Deal::Base.get(params[:id], @user.id)
    raise "Could not get deal #{params[:id]}" unless deal
    
    deal.confirm!
    
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
      updated_deal = Deal::Base.find(:first, :conditions => ["id = ? and user_id = ?", options[:updated_deal_id], @user.id])
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
      @deals = Deal::Base.get_for_month(@user.id, @target_month)
      # TODO: 外にだしたい
      session[:target_month] = @target_month
    rescue Exception => e
      p e.to_s
      e.backtrace.each do |t|
        p t
      end
      flash.now[:notice] = "不正な日付です。 " + @target_month.to_s
      @deals = Array.new
    end
  end
  
  def specify_month
    redirect_to_index and return false if !params[:year] || !params[:month]
  end

  # 記入エリアの準備
  def prepare_select_deal_tab
    @accounts_minus = ApplicationHelper::AccountGroup.groups(
      @user.accounts, true
    )
    @accounts_plus = ApplicationHelper::AccountGroup.groups(
      @user.accounts, false
    )
    unless @deal
      @deal = Deal::General.new(params[:deal])
      @deal.date = target_date # セッションから判断した日付を入れる
    end

    @patterns = [] # 入力支援
  end

  def prepare_select_balance_tab
    @accounts_for_balance = current_user.assets
    @deal ||=  Deal::Balance.new(:account_id => @accounts_for_balance.id)
  end

end