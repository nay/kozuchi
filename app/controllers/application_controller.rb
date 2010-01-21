# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
#  include LoginEngine
#  include LoginEngine::AuthenticatedSystem
  mobile_filter
  trans_sid
  include AuthenticatedSystem
  before_filter :set_content_type_for_mobile
  before_filter :login_required, :load_user, :set_ssl
  helper :all
  helper_method :original_user
  attr_writer :menu_group, :menu

  # Deal 編集系アクション群を宣言するメタメソッド

  # options - :render_options_proc, :redirect_options_proc
  def self.deal_actions_for(*args)
    options = args.extract_options!
    # 必須オプションチェック
    render_options_proc = options[:render_options_proc]
    redirect_options_proc = options[:redirect_options_proc]
    raise "render_options_proc and redirect_options_proc are required" unless render_options_proc && redirect_options_proc

    args.each do |deal_type|
      render_options = render_options_proc.call(deal_type)
      # new_xxx
      case deal_type.to_s
      when /general/
        define_method "new_#{deal_type}" do
          @deal = @user.general_deals.build
          @deal.build_simple_entries
          flash[:"#{controller_name}_deal_type"] = deal_type # reloadに強い
          render render_options
        end
      when /balance/
        define_method "new_#{deal_type}" do
          @deal = @user.balance_deals.build
          flash[:"#{controller_name}_deal_type"] = deal_type # reloadに強い
          render render_options
        end
      end

      # create_xxx
      define_method "create_#{deal_type}" do
        @deal = @user.send(deal_type.to_s =~ /general/ ? 'general_deals' : 'balance_deals').new(params[:deal])

        if @deal.save
          flash[:notice] = "#{@deal.human_name} を追加しました。" # TODO: 他コントーラとDRYに
          flash[:"#{controller_name}_deal_type"] = deal_type
          flash[:day] = @deal.date.day
          render :update do |page|
            page.redirect_to redirect_options_proc.call(@deal)
          end
        else
          render :update do |page|
            page[:deal_forms].replace_html render_options
          end
        end
      end
    end
  end




  # メニューグループを指定する
  def self.menu_group(menu_group, options = {})
    before_filter(options) {|controller| controller.menu_group = menu_group}
  end
  # メニューを指定する
  def self.menu(menu, options = {})
    before_filter(options) {|controller| controller.menu = menu}
  end
  

  def self.use_calendar(url_method = nil)
    include WithCalendar
    write_inheritable_attribute(:calendar_url_method, url_method)
  end
  
  def self.calendar_url_method
    read_inheritable_attribute(:calendar_url_method)
  end

  def original_user
    @original_user ||= User.find_by_id(session[:original_user_id]) if session[:original_user_id]
    @original_user
  end

  def original_user=(user)
    session[:original_user_id] = user ? user.id : nil
    @original_user = user || false
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
    if (defined? KOZUCHI_SSL) && KOZUCHI_SSL
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

  def require_mobile
    raise UnexpectedUserAgentError unless request.mobile?
  end
end
