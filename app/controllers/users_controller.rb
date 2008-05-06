class UsersController < ApplicationController
  skip_before_filter :login_required
  layout 'login'

  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
#      self.current_user = @user
#      redirect_back_or_default('/')
      redirect_to login_path
      flash[:notice] = "ご登録ありがとうございます。確認メールが送信されますので、記載されているURLからアカウントを有効にしてください。確認メールが届かないときは #{SUPPORT_EMAIL_ADDRESS} までお問い合わせ下さい。"
    else
      render :action => 'new'
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end

end
