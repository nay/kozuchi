require File.dirname(__FILE__) + '/../test_helper'
require_dependency 'user_controller'


# Raise errors beyond the default web-based presentation
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  
  # load the fixture into the developer-specified table using the custom
  # 'fixture' method.
  fixture :users, :table_name => LoginEngine.config(:user_table), :class_name => "User"
  
  def setup
    
    LoginEngine::CONFIG[:salt] = "test-salt"
    
    @controller = UserController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
  end


  
  #==========================================================================
  #
  # Login/Logout
  #
  #==========================================================================

  def test_home_without_login
    get :home
    assert_redirected_to :action => "login"
  end

  def test_invalid_login
    post :login, :user => { :login => "bob", :password => "wrong_password" }
    assert_response :success

    assert_session_has_no :user
    assert_template "login"
  end
 
  def test_login
    @request.session['return-to'] = "/bogus/location"

    post :login, :user => { :login => "bob", :password => "atest" }
    
    assert_response 302  # redirect
    assert_session_has :user
    assert_equal users(:bob), session[:user]
    
    assert_redirect_url "http://#{@request.host}/bogus/location"
  end

  def test_login_logoff

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    get :logout
    assert_session_has_no :user

  end


  #==========================================================================
  #
  # Signup
  #
  #==========================================================================

  def test_signup
    LoginEngine::CONFIG[:use_email_notification] = true

    ActionMailer::Base.deliveries = []

    @request.session['return-to'] = "/bogus/location"

    assert_equal 5, User.count
    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "newbob@test.com" }
    assert_session_has_no :user

    assert_redirect_url(@controller.url_for(:action => "login"))
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries[0]
    assert_equal "newbob@test.com", mail.to_addrs[0].to_s
    assert_match /login:\s+\w+\n/, mail.encoded
    assert_match /password:\s+\w+\n/, mail.encoded
    #mail.encoded =~ /user_id=(.*?)&key=(.*?)"/
    user_id = /user_id=(\d+)/.match(mail.encoded)[1]
    key = /key=([a-z0-9]+)/.match(mail.encoded)[1]

    assert_not_nil user_id
    assert_not_nil key

    user = User.find_by_email("newbob@test.com")
    assert_not_nil user
    assert_equal 0, user.verified

    # First past the expiration.
    Time.advance_by_days = 1
    get :home, :user_id => "#{user_id}", :key => "#{key}"
    Time.advance_by_days = 0
    user = User.find_by_email("newbob@test.com")
    assert_equal 0, user.verified

    # Then a bogus key.
    get :home, :user_id => "#{user_id}", :key => "boguskey"
    user = User.find_by_email("newbob@test.com")
    assert_equal 0, user.verified

    # Now the real one.
    get :home, :user_id => "#{user_id}", :key => "#{key}"
    user = User.find_by_email("newbob@test.com")
    assert_equal 1, user.verified

    post :login, :user => { :login => "newbob", :password => "newpassword" }
    assert_session_has :user
    get :logout

  end
  
  def test_signup_bad_password
    LoginEngine::CONFIG[:use_email_notification] = true
    ActionMailer::Base.deliveries = []

    @request.session['return-to'] = "/bogus/location"
    post :signup, :user => { :login => "newbob", :password => "bad", :password_confirmation => "bad", :email => "newbob@test.com" }
    assert_session_has_no :user
    assert_invalid_column_on_record "user", "password"
    assert_success
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
  
  def test_signup_bad_email
    LoginEngine::CONFIG[:use_email_notification] = true
    ActionMailer::Base.deliveries = []

    @request.session['return-to'] = "/bogus/location"

    ActionMailer::Base.inject_one_error = true
    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "newbob@test.com" }
    assert_session_has_no :user
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_signup_without_email
    LoginEngine::CONFIG[:use_email_notification] = false
    
    @request.session['return-to'] = "/bogus/location"

    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "newbob@test.com" }

    assert_redirect_url(@controller.url_for(:action => "login"))    
    assert_session_has_no :user
    assert_match /Signup successful/, flash[:notice]
    
    assert_not_nil User.find_by_login("newbob")
    
    user = User.find_by_email("newbob@test.com")
    assert_not_nil user
    
    post :login, :user => { :login => "newbob", :password => "newpassword" }
    assert_session_has :user
    get :logout    
  end

  def test_signup_bad_details
    @request.session['return-to'] = "/bogus/location"

    # mismatched password
    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "wrong" }
    assert_invalid_column_on_record "user", "password"
    assert_success
    
    # login not long enough
    post :signup, :user => { :login => "yo", :password => "newpassword", :password_confirmation => "newpassword" }
    assert_invalid_column_on_record "user", "login"
    assert_success

    # both
    post :signup, :user => { :login => "yo", :password => "newpassword", :password_confirmation => "wrong" }
    assert_invalid_column_on_record "user", ["login", "password"]
    assert_success
    
    # existing user
    post :signup, :user => { :login => "bob", :password => "doesnt_matter", :password_confirmation => "doesnt_matter" }
    assert_invalid_column_on_record "user", "login"
    assert_success

    # existing email
    post :signup, :user => { :login => "newbob", :email => "longbob@test.com", :password => "doesnt_matter", :password_confirmation => "doesnt_matter" }
    assert_invalid_column_on_record "user", "email"
    assert_success

  end
  

  #==========================================================================
  #
  # Edit
  #
  #==========================================================================
  
  def test_edit
    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    post :edit, :user => { "firstname" => "Bob", "form" => "edit" }
    assert_equal @response.session[:user].firstname, "Bob"

    post :edit, :user => { "firstname" => "", "form" => "edit" }
    assert_equal @response.session[:user].firstname, ""

    get :logout
  end



  #==========================================================================
  #
  # Delete
  #
  #==========================================================================

  def test_delete
    LoginEngine::CONFIG[:use_email_notification] = true
    # Immediate delete
    post :login, :user => { :login => "deletebob1", :password => "alongtest" }
    assert_session_has :user

    LoginEngine.config :delayed_delete, false, :force
    post :delete
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_session_has_no :user
    
    # try and login in again, we should fail.
    post :login, :user => { :login => "deletebob1", :password => "alongtest" }
    assert_session_has_no :user
    assert_template_has "login"
    

    # Now try delayed delete
    ActionMailer::Base.deliveries = []

    post :login, :user => { :login => "deletebob2", :password => "alongtest" }
    assert_session_has :user

    LoginEngine.config :delayed_delete, true, :force
    post :delete
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries[0]
    user_id = /user_id=(\d+)/.match(mail.encoded)[1]
    key = /key=([a-z0-9]+)/.match(mail.encoded)[1]
    
    post :restore_deleted, :user_id => "#{user_id}", "key" => "badkey"
    assert_session_has_no :user

    # Advance the time past the delete date
    Time.advance_by_days = LoginEngine.config :delayed_delete_days
    post :restore_deleted, :user_id => "#{user_id}", "key" => "#{key}"
    assert_session_has_no :user
    Time.advance_by_days = 0

    post :restore_deleted, :user_id => "#{user_id}", "key" => "#{key}"
    assert_session_has :user      
  end
  
  def test_delete_without_email
    LoginEngine::CONFIG[:use_email_notification] = false
    ActionMailer::Base.deliveries = []

    # Immediate delete
    post :login, :user => { :login => "deletebob1", :password => "alongtest" }
    assert_session_has :user

    LoginEngine.config :delayed_delete, false, :force
    post :delete
    assert_session_has_no :user
    assert_nil User.find_by_login("deletebob1")
    
    # try and login in again, we should fail.
    post :login, :user => { :login => "deletebob1", :password => "alongtest" }
    assert_session_has_no :user
    assert_template_has "login"
    

    # Now try delayed delete
    ActionMailer::Base.deliveries = []

    post :login, :user => { :login => "deletebob2", :password => "alongtest" }
    assert_session_has :user

    # delayed delete is not really relevant currently without email.
    LoginEngine.config :delayed_delete, true, :force
    post :delete
    assert_equal 1, User.find_by_login("deletebob2").deleted
  end



  #==========================================================================
  #
  # Change Password
  #
  #==========================================================================

  def test_change_valid_password
    
    LoginEngine::CONFIG[:use_email_notification] = true
    
    ActionMailer::Base.deliveries = []

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    post :change_password, :user => { :password => "changed_password", :password_confirmation => "changed_password" }
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries[0]
    assert_equal "bob@test.com", mail.to_addrs[0].to_s
    assert_match /login:\s+\w+\n/, mail.encoded
    assert_match /password:\s+\w+\n/, mail.encoded

    post :login, :user => { :login => "bob", :password => "changed_password" }
    assert_session_has :user
    post :change_password, :user => { :password => "atest", :password_confirmation => "atest" }
    get :logout

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    get :logout
  end

  def test_change_valid_password_without_email
    
    LoginEngine::CONFIG[:use_email_notification] = false
    
    ActionMailer::Base.deliveries = []

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    post :change_password, :user => { :password => "changed_password", :password_confirmation => "changed_password" }
    
    assert_redirected_to :action => "change_password"

    post :login, :user => { :login => "bob", :password => "changed_password" }
    assert_session_has :user
    post :change_password, :user => { :password => "atest", :password_confirmation => "atest" }
    get :logout

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    get :logout
  end

  def test_change_short_password
    LoginEngine::CONFIG[:use_email_notification] = true
    ActionMailer::Base.deliveries = []

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    post :change_password, :user => { :password => "bad", :password_confirmation => "bad" }
    assert_invalid_column_on_record "user", "password"
    assert_success
    assert_equal 0, ActionMailer::Base.deliveries.size    

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    get :logout
  end
  
  def test_change_short_password_without_email
    LoginEngine::CONFIG[:use_email_notification] = false
    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    post :change_password, :user => { :password => "bad", :password_confirmation => "bad" }
    assert_invalid_column_on_record "user", "password"
    assert_success

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    get :logout
  end


  def test_change_password_with_bad_email
    LoginEngine::CONFIG[:use_email_notification] = true
    ActionMailer::Base.deliveries = []
    
    # log in
    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    # change the password, but the email delivery will fail
    ActionMailer::Base.inject_one_error = true
    post :change_password, :user => { :password => "changed_password", :password_confirmation => "changed_password" }
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_match /Password could not be changed/, flash[:warning]
    
    # logout
    get :logout
    assert_session_has_no :user

    # ensure we can log in with our original password
    # TODO: WHY DOES THIS FAIL!! It looks like the transaction stuff in UserController#change_password isn't actually rolling back changes.
    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    get :logout
  end




  #==========================================================================
  #
  # Forgot Password
  #
  #==========================================================================

  def test_forgot_password
    LoginEngine::CONFIG[:use_email_notification] = true

    do_forgot_password(false, false, false)
    do_forgot_password(false, false, true)
    do_forgot_password(true, false, false)
    do_forgot_password(false, true, false)
  end
  
  def do_forgot_password(bad_address, bad_email, logged_in)
    ActionMailer::Base.deliveries = []

    if logged_in
      post :login, :user => { :login => "bob", :password => "atest" }
      assert_session_has :user
    end

    @request.session['return-to'] = "/bogus/location"
    if not bad_address and not bad_email
      post :forgot_password, :user => { :email => "bob@test.com" }
      password = "anewpassword"
      if logged_in
        assert_equal 0, ActionMailer::Base.deliveries.size
        assert_redirect_url(@controller.url_for(:action => "change_password"))
        post :change_password, :user => { :password => "#{password}", :password_confirmation => "#{password}" }
      else
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = ActionMailer::Base.deliveries[0]
        assert_equal "bob@test.com", mail.to_addrs[0].to_s
        user_id = /user_id=(\d+)/.match(mail.encoded)[1]
        key = /key=([a-z0-9]+)/.match(mail.encoded)[1]
        post :change_password, :user => { :password => "#{password}", :password_confirmation => "#{password}"}, :user_id => "#{user_id}", :key => "#{key}"
        assert_session_has :user
        get :logout
      end
    elsif bad_address
      post :forgot_password, :user => { :email => "bademail@test.com" }
      assert_equal 0, ActionMailer::Base.deliveries.size
    elsif bad_email
      ActionMailer::Base.inject_one_error = true
      post :forgot_password, :user => { :email => "bob@test.com" }
      assert_equal 0, ActionMailer::Base.deliveries.size
    else
      # Invalid test case
      assert false
    end

    if not bad_address and not bad_email
      if logged_in
        get :logout
      else
        assert_redirect_url(@controller.url_for(:action => "login"))
      end
      post :login, :user => { :login => "bob", :password => "#{password}" }
    else
      # Okay, make sure the database did not get changed
      if logged_in
        get :logout
      end
      post :login, :user => { :login => "bob", :password => "atest" }
    end

    assert_session_has :user

    # Put the old settings back
    if not bad_address and not bad_email
      post :change_password, :user => { :password => "atest", :password_confirmation => "atest" }
    end
    
    get :logout
  end

  def test_forgot_password_without_email_and_logged_in
    LoginEngine::CONFIG[:use_email_notification] = false

    post :login, :user => { :login => "bob", :password => "atest" }
    assert_session_has :user

    @request.session['return-to'] = "/bogus/location"
    post :forgot_password, :user => { :email => "bob@test.com" }
    password = "anewpassword"
    assert_redirect_url(@controller.url_for(:action => "change_password"))
    post :change_password, :user => { :password => "#{password}", :password_confirmation => "#{password}" }

    get :logout

    post :login, :user => { :login => "bob", :password => "#{password}" }

    assert_session_has :user
    
    get :logout
  end

  def forgot_password_without_email_and_not_logged_in
    LoginEngine::CONFIG[:use_email_notification] = false

    @request.session['return-to'] = "/bogus/location"
    post :forgot_password, :user => { :email => "bob@test.com" }
    password = "anewpassword"

    # wothout email, you can't retrieve your forgotten password...
    assert_match /Please contact the system admin/, flash[:message]
    assert_session_has_no :user

    assert_redirect_url "http://#{@request.host}/bogus/location"
  end  
end
