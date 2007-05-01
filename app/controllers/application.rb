require 'login_engine'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include LoginEngine
  helper :user
  model :user
  
  before_filter :login_required
  before_filter :set_charset
  before_filter :set_ssl



  # -- login_engine overwrite
  def access_denied
    redirect_to :controller => "/user", :action => "login"
    false # なぜかもともとこれがなかったorz
  end


  def user
    session[:user]
  end

#  def rescue_action_in_public(exception)
#    p "rescue"
#    redirect_to(:controller => 'deals', :action => 'index')
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
    @user = session[:user]
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
