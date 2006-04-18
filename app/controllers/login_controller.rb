class LoginController < ApplicationController
  before_filter :authorize, :except => :login

  def login
    if request.get?
      session[:user] =  nil
      @user = User.new
      return
    end

    @user = User.new(params[:user])
    logged_in_user = @user.try_to_login
    if logged_in_user
      session[:user] = logged_in_user
      redirect_to(:controller => "book", :action => "deals")
    else
      flash[:notice] = "ログインに失敗しました。"
      @user.password = ""
    end
  end

  def logout
      reset_session
      flash[:notice] = "ログアウトしました。"
      redirect_to(:action => "login")
  end
end
