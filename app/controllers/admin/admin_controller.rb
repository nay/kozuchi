class Admin::AdminController < ApplicationController

  skip_before_filter :login_required
  before_filter :require_admin_login, :except => ['login', 'logout']

  def login
    p "login"
    if request.get?
      clear_admin_session
      @admin_user = AdminUser.new
    else
      @admin_user = AdminUser.new(params[:admin_user])
      logged_in_user = @admin_user.try_to_login
      p "logged_in_user = #{logged_in_user}"
      if logged_in_user
        session[:admin_user] = logged_in_user
        p "stored in session"
        redirect_to :controller => '/admin/analytics', :action => 'users'
      else
        flash[:notice] = "ログインできません。"
      end
    end
  end

  def logout
    clear_admin_session
    p "redirect_to_login"
    redirect_to :action => 'login'
  end


  # protected --------------------------------------------------------------------------
  protected
  
  def clear_admin_session
    session[:admin_user] = nil
  end

  def require_admin_login
    p "require_admin_login"
    p session[:admin_user]
    unless session[:admin_user]
      redirect_to :controller => 'admin', :action => 'login'
      return false
    end
    return true
  end
  
end
