# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  before_filter :set_charset

  def flash_validation_errors(obj)
    flash[:errors] ||= []
    obj.errors.each do |attr, msg|
      flash[:errors] << msg
    end
  end
  
  def flash_error(message)
    flash[:errors] ||= []
    flash[:errors] << message
  end
  
  def flash_notice(message)
    flash[:notice] = message
  end

  def authorize
    unless session[:user]
      flash[:notice] = "ログインしてください。"
      p "authorize"
      redirect_to(:controller => 'login', :action => 'index')
    end
  end
  
  protected
  def set_charset
    @headers["Content-Type"] = 'text/html; charset=utf-8'
  end
end
