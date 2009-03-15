# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
#  include LoginEngine
#  include LoginEngine::AuthenticatedSystem
  mobile_filter
  transit_sid
  include AuthenticatedSystem
  init_gettext "kozuchi"
  before_filter :set_content_type_for_mobile
  before_filter :login_required, :load_user, :set_ssl
  helper :all
  
  before_filter :load_menues
  
  def self.use_calendar(url_method = nil)
    include WithCalendar
    write_inheritable_attribute(:calendar_url_method, url_method)
  end
  
  def self.calendar_url_method
    read_inheritable_attribute(:calendar_url_method)
  end
  
  private

  def set_content_type_for_mobile
    headers["Content-Type"] = "text/html; chartset=Shift_JIS" if request.mobile?
  end
  
  def IE6?
    request.user_agent =~ /MSIE 6.0/ && !(request.user_agent =~ /Opera/)
  end
  
#  # LoginEngine login_required を overwrite。以下の目的。
#  # * session 内に user_id だけを入れるようにしたことに対応するため。
#  # * 認証OKの場合に @user をセットするため
#  def login_required
##    if not protect?(action_name)
##      return true  
##    end
#
#    if user? and authorize?(User.find(session[:user_id]))
#      load_user
#      return true
#    end
#
#    # store current location so that we can 
#    # come back after the user logged in
#    store_location
#  
#    # call overwriteable reaction to unauthorized access
#    access_denied
#  end
  
  # session に user_id を入れるためオーバーライト
  def user?
    # First, is the user already authenticated?
    return true if not session[:user_id].nil?

    # If not, is the user being authenticated by a token?
    id = params[:user_id]
    key = params[:key]
    if id and key
      u = User.authenticate_by_token(id, key)
      session[:user_id] = u.id if u
      return true if not session[:user_id].nil?
    end

    # Everything failed
    return false
  end
  
#  # Returns the current user from the session, if any exists
#  #
#  # session に user_id を入れるためオーバーライト
#  def current_user
#    User.find(session[:user_id].to_i)
#  end

#  # login_engine overwrite
#  def access_denied
#    redirect_to :controller => "/user", :action => "login"
#    false # なぜかもともとこれがなかったorz
#  end

#  # deprecated
#  def user
#    User.find(session[:user_id])
#  end
  
  # 開発環境でエラーハンドリングを有効にしたい場合にコメントをはずす
#  def local_request?
#    false
#  end


  def set_ssl
    if KOZUCHI_SSL
      request.env["HTTPS"] = "on"
    end
  end

  def flash_validation_errors(obj, now = false)
    f = now ? flash.now : flash
    
    f[:errors] ||= []
    obj.errors.each do |attr, msg|
      f[:errors] << msg
    end
  end
  
  def flash_error(message, now = false)
    # TODO: validation error で Validation Failed が出るのを防ぐ
    begin
      message = message.gsub(/Validation failed: /, '')
    rescue
    end
    
    f = now ? flash.now : flash
    f[:errors] ||= []
    f[:errors] << message
  end
  
  def flash_notice(message, now = false)
    f = now ? flash.now : flash
    f[:notice] = message
  end


#  def load_menues
#    @menu_tree, @current_menu = ApplicationHelper::Menues.side_menues.load(:controller => "/" + self.class.controller_path, :action => self.action_name)
#    @title = @menu_tree ? @menu_tree.name : self.class.controller_name
#    @sub_title = @current_menu ? @current_menu.name : self.action_name
#  end
  
  # @target_month と @date をセットする
  # TODO: 新方式に切り替えたので呼び出し元を変更したい
  def prepare_date
    @target_month = DateBox.new(target_date)
    @date = @target_month
  end
  
  # 編集対象日をセッションに保存する
  def target_date=(date)
    if date.kind_of?(Date)
      session[:target_date] = {:year => date.year, :month => date.month, :day => date.day}
    else
      session[:target_date] = date
    end
    
  end

  # セッションに入っているyear, month, dayを配列で返す
  def read_target_date
    year = session[:target_date] ? session[:target_date][:year] : nil
    month = year ? session[:target_date][:month] : nil
    day = month ? session[:target_date][:day] : nil
    [year, month, day]
  end
  
  # セッションに入っているyear, month, dayを更新する
  def write_target_date(year, month = nil, day = nil)
    session[:target_date] ||= {}
    session[:target_date][:year] = year
    session[:target_date][:month] = year ? month : nil
    session[:target_date][:day] = month ? day : nil
  end

  # 編集対象日のハッシュを得る
  # セッションも更新する
  # dprecated.
  def target_date
    if session[:target_date] && session[:target_date][:year] && session[:target_date][:month]
      # day がないときは補完できるならする
      if !session[:target_date][:day]
        today = Date.today
        session[:target_date][:day] = today.day if session[:target_date][:year].to_s == today.year.to_s && session[:target_date][:month].to_s == today.month.to_s
      end
    else
      today = Date.today
      session[:target_date] = {:year => today.year, :month => today.month, :day => today.day}
    end
    return session[:target_date]
  end
  
  def load_target_date
    @target_date = target_date
    raise "no target_date" unless @target_date
  end
  
  # @target_month をもとにして資産の残高を計算する
  # TODO: 先に @user が用意されている前提
  def load_assets
    date = Date.new(target_date[:year].to_i, target_date[:month].to_i, 1) >> 1
    asset_accounts = @user.accounts.balances(date, "accounts.type != 'Income' and accounts.type != 'Expense'") # TODO: マシにする
    @assets = AccountsBalanceReport.new(asset_accounts, date)
  end
    
  #TODO: どこかにありそうなきがするが・・・
  def to_date(hash)
    raise "no hash" unless hash
    Date.new(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
  end

  # 指定されたURLがない旨のページを表示する。
  # もとのURLのまま表示されるよう、redirectはしない。
  # filter内で使って便利なよう、false を返す。
  def error_not_found
    raise ActiveRecord::RecordNotFound # TODO
#    render :template => '/open/not_found', :layout => 'login'
#    false
  end

#  # 例外ハンドリング
#  def rescue_action_in_public(exception)
#    return error_not_found if exception.class.to_s == "ActionController::UnknownAction" # 例外クラスが見えないので文字列で比較
#    logger.error(exception)
#    render :text => "error(#{exception.class}). #{exception} #{exception.backtrace}"
#  end

  # ユーザーオブジェクトを@userに取得する。なければnilが入る。
  def load_user
    @user = self.current_user
  end

  # post でない場合は error_not_found にする
  def require_post
    return error_not_found unless request.post?
    true
  end

  # 資産口座が1つ以上あり、全部で２つ以上の口座がないとダメ
  def check_account
    raise "no user" unless current_user
    if current_user.assets.size < 1 || current_user.accounts.size < 2
      render("book/need_accounts")
      return false
    end
    true
  end
  
  def load_menues
    # Prepare Menu Items
    @header_menues = MenuTree.new
    @header_menues.add_menu 'ホーム', :controller => "/home", :action => 'index'
    @header_menues.add_menu '家計簿', :controller => "/deals", :action => 'index'
    @header_menues.add_menu '精算',  :controller => '/settlements', :action => 'new'
    @header_menues.add_menu '基本設定', :controller => "/settings/assets", :action => "index"
    @header_menues.add_menu '高度な設定', :controller => "/settings/friends", :action => "index"
    @header_menues.add_menu 'ヘルプ', :controller => "/help", :action => "index"
    @header_menues.add_menu 'ログアウト', logout_path

    @side_menues = Menues.new
    @side_menues.create_menu_tree('家計簿') do |t|
      t.add_menu('仕訳帳', :controller => '/deals', :action => 'index')
#        t.add_menu('日めくり', :controller => '/daily_booking', :action => 'index')
      t.add_menu('口座別出納', :controller => 'account_deals')
      t.add_menu('収支表', :controller => '/profit_and_loss', :action => 'index')
      t.add_menu('資産表', :controller => '/assets', :action => 'index')
      t.add_menu('貸借対照表', :controller => '/balance_sheet', :action => 'index')
    end
    
    @side_menues.create_menu_tree('精算') do |t|
      t.add_menu('新しい精算', :controller => '/settlements', :action => 'new')
      t.add_menu('一覧', :controller => '/settlements', :action => 'index')
      t.add_menu('詳細', :controller => '/settlements', :action => 'view')
    end
    
    @side_menues.create_menu_tree('基本設定') do |t|
      t.add_menu('口座', :controller => '/settings/assets', :action => 'index')
      t.add_menu('費目', :controller => '/settings/expenses',:action => 'index')
      t.add_menu('収入内訳', :controller => '/settings/incomes',:action => 'index')
      t.add_menu('プロフィール', :controller => '/users',:action => 'edit')
    end
    
    @side_menues.create_menu_tree('高度な設定') do |t|
      t.add_menu('フレンド', :controller => '/settings/friends',:action => 'index')
      t.add_menu('取引連動',:controller => '/settings/account_links', :action => 'index')
      t.add_menu('受け皿', :controller => '/settings/partner_account', :action => 'index')
      t.add_menu('カスタマイズ', :controller => '/settings/preferences',:action => 'index')
    end
    
    @side_menues.create_menu_tree('ヘルプ') do |t|
      t.add_menu('小槌の特徴', :controller => '/help', :action => 'index')
      t.add_menu('できること', :controller => '/help', :action => 'functions')
      t.add_menu('FAQ', :controller => '/help', :action => 'faq')
    end
  end

  def require_mobile
    raise UnexpectedUserAgentError unless request.mobile?
  end
end
