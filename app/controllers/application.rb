# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  before_filter :set_charset
  before_filter :set_ssl

  def rescue_action_in_public(exception)
    p "rescue"
    redirect_to(:controller => 'deals', :action => 'index')
  end
  

  def set_ssl
    if KOZUCHI_SSL
      request.env["HTTPS"] = "on"
    end
  end

  def flash_validation_errors(obj)
    flash[:errors] ||= []
    obj.errors.each do |attr, msg|
      flash[:errors] << msg
    end
  end
  
  def flash_error(message)
    # TODO: validation error で Validation Failed が出るのを防ぐ
    message = message.gsub(/Validation failed: /, '')
  
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
