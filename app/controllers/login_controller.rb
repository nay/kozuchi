class LoginController < ApplicationController
  before_filter :authorize, :except => :index
  layout 'login'
  
  def index
    if request.get?
      session[:user] =  nil
      @user = User.new
      return
    end

    @user = User.new(params[:user])
    logged_in_user = @user.try_to_login
    if logged_in_user
      session[:user] = logged_in_user
      redirect_to(:controller => 'deals', :action => 'index')
    else
      flash[:notice] = "ログインに失敗しました。"
      @user.password = ""
      redirect_to(:action => 'index') # post でなくするため
    end
  end

  def login
    redirect_to(:index => "index")
  end

  def logout
      reset_session
      flash[:notice] = "ログアウトしました。"
      redirect_to(:action => "login")
  end
  
end
