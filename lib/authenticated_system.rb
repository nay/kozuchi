module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      !!current_user
    end

    # 今のユーザー。いなければ false を覚えて、同じリクエストの中では探し直さない
    def current_user
      self.current_user = (session[:user_id] ? session_user : (basic_auth_user || cookie_user)) if @current_user.nil? # Basic 認証と Cookie は、セッションにユーザーがないときだけ使う
      @current_user || nil # 呼ぶ側には、いないときは今までどおり nil を返す
    end

    # Store the given user id in the session.
    def current_user=(new_user)
      session[:user_id] = new_user ? new_user.id : nil
      @current_user = new_user || false
    end

    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    def authorized?
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_action :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_action :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_action :login_required
    #
    def login_required
      authorized? || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to root_path # new_session_path
        end
        format.any do
          request_http_basic_authentication 'Web Password'
        end
      end
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.fullpath
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?
    end

    def session_user
      User.find_by(id: session[:user_id])
    end

    def basic_auth_user
      authenticate_with_http_basic { |username, password| User.authenticate(username, password) }
    end

    # 「ログイン状態を記憶」の Cookie の合言葉が、期限内で合うユーザー
    def cookie_user
      user = cookies[:auth_token] && User.find_by(remember_token: cookies[:auth_token])
      user if user&.remember_token?
    end
end
