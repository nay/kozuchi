# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  layout 'login' # TODO: リファクタリング
  skip_before_filter :login_required
  
  # functional test のために残している
  def new
    render :nothing => true
  end

  def create
    if params[:submit] != "簡単ログイン"
      self.current_user = User.authenticate(params[:login], params[:password])
    end
    if logged_in? # utnを使った簡単ログインの場合、上記をスキップしてここで自動ログインされる
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(url_for(:controller => 'home', :action => 'index'))
    else
      flash[:error] = "ログインに失敗しました。"
      flash[:login] = params[:login]
      redirect_to root_path
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(root_path)
  end
end
