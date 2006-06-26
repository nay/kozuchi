class UserController < ApplicationController
  include ConfigMenues
  model   :user
  layout  'login'

  # Override this function in your own application to define a custom home action.
  def home
    if user?
      @fullname = "#{current_user.firstname} #{current_user.lastname}"
    else
      @fullname = "Not logged in..."
    end # this is a bit of a hack since the home action is used to verify user
        # keys, where noone is logged in. We should probably create a unique
        # 'validate_key' action instead.
  end

  # The action used to log a user in. If the user was redirected to the login page
  # by the login_required method, they should be sent back to the page they were
  # trying to access. If not, they will be sent to "/user/home".
  def login
    reset_session
    return if generate_blank
    @user = User.new(params[:user])
    if session[:user] = User.authenticate(params[:user][:login], params[:user][:password])
      session[:user].logged_in_at = Time.now
      session[:user].save
#      flash[:notice] = 'Login successful'
#      redirect_to_stored_or_default :action => 'home'
      redirect_to_stored_or_default :controller => 'deals', :action => 'index'
    else
      @login = params[:user][:login]
#      flash.now[:warning] = 'Login unsuccessful'
      flash_error('ログインに失敗しました。')
      redirect_to :action => 'login' # avoid post
    end
  end

  # Register as a new user. Upon successful registration, the user will be sent to
  # "/user/login" to enter their details.
  def signup
    return if generate_blank
    params[:user].delete('form')
    params[:user].delete('verified') # you CANNOT pass this as part of the request
    @user = User.new(params[:user])
    begin
      User.transaction(@user) do
        @user.new_password = true
        unless LoginEngine.config(:use_email_notification) and LoginEngine.config(:confirm_account)
          @user.verified = 1
        end
        if @user.save
          key = @user.generate_security_token
          url = url_for(:action => 'home', :user_id => @user.id, :key => key)
          flash[:notice] = '登録は正常に受け付けられました。'
          if LoginEngine.config(:use_email_notification) and LoginEngine.config(:confirm_account)
            UserNotify.deliver_signup(@user, params[:user][:password], url)
            flash[:notice] << ' 登録確認メールを確認して登録処理を完了してください。'
          else
            flash[:notice] << ' ログインしてください。'
          end
          redirect_to :action => 'login'
        end
      end
    rescue Exception => e
      flash.now[:notice] = nil
      flash.now[:warning] = 'Error creating account: confirmation email not sent'
      flash_error("アカウント作成時にエラーが発生しました。（登録確認メールは送られていません。）")
      logger.error "Unable to send confirmation E-Mail:"
      logger.error e
    end
  end

  def logout
#    session[:user] = nil
    reset_session
    redirect_to :action => 'login'
  end

  # メニューからはプロファイルのみ
#  def change_password
#    return if generate_filled_in(:layout => 'main')
##    return if generate_filled_in
#    if do_change_password_for(@user)
#      # since sometimes we're changing the password from within another action/template...
#      #redirect_to :action => params[:back_to] if params[:back_to]
#      redirect_back_or_default :action => 'change_password'
#    end
#  end

  protected
    def do_change_password_for(user)
      begin
        User.transaction(user) do
          user.change_password(params[:user][:password], params[:user][:password_confirmation])
          if user.save
#            if LoginEngine.config(:use_email_notification)
#              UserNotify.deliver_change_password(user, params[:user][:password])
#              flash[:notice] = "Updated password emailed to #{@user.email}"
#            else
              flash_notice("パスワードが変更されました。")
#            end
            return true
          else
            flash_error('パスワードを変更できませんでした。')
            return false
          end
        end
      rescue
         flash_error('パスワードを変更できませんでした。')
#        flash[:warning] = 'Password could not be changed at this time. Please retry.'
      end
    end
    
  public


  def forgot_password
    # Always redirect if logged in
    if user?
      flash[:message] = 'You are currently logged in. You may change your password now.'
#      redirect_to :action => 'change_password'
      redirect_to :action => 'edit'
      return
    end

    # Email disabled... we are unable to provide the password
    if !LoginEngine.config(:use_email_notification)
      flash[:message] = "Please contact the system admin at #{LoginEngine.config(:admin_email)} to reset your password."
      redirect_back_or_default :action => 'login'
      return
    end

    # Render on :get and render
    return if generate_blank

    # Handle the :post
    if params[:user][:email].empty?
#      flash.now[:warning] = 'Please enter a valid email address.'
      flash_error('正しいEメールアドレスを入力してください。')
    elsif (user = User.find_by_email(params[:user][:email])).nil?
      flash_error("メールアドレス #{params[:user][:email]} に該当するユーザーは登録されていません。")
    else
      begin
        User.transaction(user) do
          key = user.generate_security_token
#          url = url_for(:action => 'change_password', :user_id => user.id, :key => key)
          url = url_for(:action => 'edit', :user_id => user.id, :key => key)
          UserNotify.deliver_forgot_password(user, url)
#          flash[:notice] = "Instructions on resetting your password have been emailed to #{params[:user][:email]}"
          flash_notice("パスワード再設定のための情報を #{params[:user][:email]}　へ送信しました。")
        end
        unless user?
          redirect_to :action => 'login'
          return
        end
        redirect_back_or_default :action => 'home'
      rescue
#        flash.now[:warning] = "Your password could not be emailed to #{params[:user][:email]}"
        flash_error("パスワード再設定のための情報を #{params[:user][:email]} へ送信できませんでした。申し訳ありませんが管理者へご確認ください。")
      end
    end
  end

  def edit
    return if generate_filled_in(:layout => 'main')
    do_edit_user(@user)
    redirect_to(:action => 'edit') #avoid post
  end
  
  protected
    def do_edit_user(user)
      begin
        User.transaction(user) do
          user.attributes = params[:user].delete_if { |k,v| not LoginEngine.config(:changeable_fields).include?(k) }
          if user.save
            flash_notice("ユーザープロフィールが更新されました。")
          else
            flash_error("ユーザープロフィールを更新できませんでした。")
          end
        end
      rescue
        flash.now[:warning] = "ユーザープロフィールを更新できませんでした。"
      end
    end
  
  public

  def delete
    get_user_to_act_on
    if do_delete_user(@user)
      logout
    else
      redirect_back_or_default :action => 'home'
    end    
  end
  
  protected
    def do_delete_user(user)
      begin
        if LoginEngine.config(:delayed_delete)
          User.transaction(user) do
            key = user.set_delete_after
            if LoginEngine.config(:use_email_notification)
              url = url_for(:action => 'restore_deleted', :user_id => user.id, :key => key)
              UserNotify.deliver_pending_delete(user, url)
            end
          end
        else
          destroy(@user)
        end
        return true
      rescue
        if LoginEngine.config(:use_email_notification)
          flash.now[:warning] = 'The delete instructions were not sent. Please try again later.'
        else
          flash.now[:notice] = 'The account has been scheduled for deletion. It will be removed in #{LoginEngine.config(:delayed_delete_days)} days.'
        end
        return false
      end
    end
    
  public

  def restore_deleted
    get_user_to_act_on
    @user.deleted = 0
    if not @user.save
      flash.now[:warning] = "The account for #{@user['login']} was not restored. Please try the link again."
      redirect_to :action => 'login'
    else
      redirect_to :action => 'home'
    end
  end

  protected

  def destroy(user)
    UserNotify.deliver_delete(user) if LoginEngine.config(:use_email_notification)
    flash[:notice] = "The account for #{user['login']} was successfully deleted."
    user.destroy()
  end

  def protect?(action)
    if ['login', 'signup', 'forgot_password'].include?(action)
      return false
    else
      return true
    end
  end

  # Generate a template user for certain actions on get
  def generate_blank
    case request.method
    when :get
      @user = User.new
      render
      return true
    end
    return false
  end

  # Generate a template user for certain actions on get
  def generate_filled_in(render_options={})
    get_user_to_act_on
    case request.method
    when :get
      render(render_options)
      return true
    end
    return false
  end
  
  # returns the user object this method should act upon; only really
  # exists for other engines operating on top of this one to redefine...
  def get_user_to_act_on
    @user = session[:user]
  end
end
