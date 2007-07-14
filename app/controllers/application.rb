require 'login_engine'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include LoginEngine
  
  #TODO: どこかにありそうなきがするが・・・
  def to_date(hash)
    raise "no hash" unless hash
    Date.new(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
  end
  
    # login_required filter. add 
    #
    #   before_filter :login_required
    #
    # if the controller should be under any rights management. 
    # for finer access control you can overwrite
    #   
    #   def authorize?(user)
    # 
    def login_required
      p "login_required sesison[:user_id] = #{session[:user_id]}"
      if not protect?(action_name)
        return true  
      end

      if user? and authorize?(User.find(session[:user_id]))
        return true
      end

      # store current location so that we can 
      # come back after the user logged in
      store_location
  
      # call overwriteable reaction to unauthorized access
      access_denied
    end
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
  
    # Returns the current user from the session, if any exists
    def current_user
      User.find(session[:user_id].to_i)
    end

  helper :user
  model :user, 'account/base', 'account/asset', 'account/income'
  
  before_filter :login_required
  before_filter :set_charset
  before_filter :set_ssl



  # -- login_engine overwrite
  def access_denied
    redirect_to :controller => "/user", :action => "login"
    false # なぜかもともとこれがなかったorz
  end


  def user
    User.find(session[:user_id])
  end
  
  # 開発環境でエラーハンドリングを有効にしたい場合にコメントをはずす
  def local_request?
    false
  end

  def rescue_action_in_public(exception)
    # 例外クラスが見えないので文字列で比較
    if exception.class.to_s == "ActionController::UnknownAction"
      render :template => '/open/not_found', :layout => 'login'
      return
    end
    logger.error(exception)
    render :text => "error(#{exception.class}). #{exception} #{exception.backtrace}"
#    redirect_to(:controller => 'deals', :action => 'index')
  end

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


  def check_account
    if user
      # 資産口座が1つ以上あり、全部で２つ以上の口座がないとダメ
      if user.accounts.types_in(:asset).size < 1 || user.accounts.size < 2
        render("book/need_accounts")
      end
    end
  end

  protected
  # -------------------- 汎用処理 ------------------------------------------------------

  def load_menues
    @menu_tree, @current_menu = ApplicationHelper::Menues.side_menues.load(:controller => "/" + self.class.controller_path, :action => self.action_name)
    @title = @menu_tree ? @menu_tree.name : self.class.controller_name
    @sub_title = @current_menu ? @current_menu.name : self.action_name
  end

  
  def set_charset
    @headers["Content-Type"] = 'text/html; charset=utf-8'
  end
  
  # @target_month と @date をセットする
  def prepare_date
    @target_month = DateBox.new(params[:target_month]) if params[:target_month]
    @target_month ||= session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
  end
  
  def load_user
    # TODO: いずれ session には　user_id だけをのせ、毎回取得する仕組みにする
    @user = User.find(session[:user_id])
  end

  # @target_month をもとにして資産の残高を計算する
  # TODO: 先に @user が用意されている前提
  def load_assets
    date = Date.new(@target_month.year_i, @target_month.month_i, 1) >> 1
    @assets = AccountsBalanceReport.new(@user.accounts.types_in(:asset), date)
  end
  
  def error_not_found
    redirect_to :controller => 'open', :action => 'not_found'
    false
  end
  
  # post でない場合は error_not_found にする
  def require_post
    return error_not_found unless request.post?
    true
  end

  
end
