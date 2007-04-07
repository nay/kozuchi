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
      if Account.count_in_user(user.id, [Account::ACCOUNT_ASSET])< 1 || Account.count_in_user(user.id) < 2
        render("book/need_accounts")
      end
    end
  end

  protected
  def set_charset
    @headers["Content-Type"] = 'text/html; charset=utf-8'
  end
  
  # @target_month と @date をセットする
  def prepare_date
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
  end
  
  def load_user
    @user = session[:user]
  end
  
end
