# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  def authorize
    unless session[:user]
      flash[:notice] = "ログインしてください。"
      p "authorize"
      redirect_to(:controller => "login", :action => "login")
    end
  end
end