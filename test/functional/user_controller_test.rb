require File.dirname(__FILE__) + '/../test_helper'
require 'user_controller'

module LoginEngine
  config :use_email_notification, false, :force
end

# Re-raise errors caught by the controller.
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  fixtures :accounts

  def setup
    @controller = UserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # サインアップ画面が出ること
  def test_get_signup
    get :signup
    assert_response :success
    assert_template 'signup'
  end
  
  # サインアップで登録情報を送る
  def test_post_signup
    # サインアップしていないときはログインできない
    post :login, :user => {:login => 'new_user', :password => 'testtest'}
    assert_redirected_to :action => 'login'
    # サインアップする
    post :signup, :user => {:lastname => 'new_user_last', :firstname => 'new_user_first', :login => 'new_user', :email => 'new_user@meadowy.org', :password => 'testtest', :password_confirmation => 'testtest'}
    assert_redirected_to :action => 'login'
    user = User.find(:first, :conditions => "lastname = 'new_user_last'")
    assert_not_nil(user)
    assert(user.verified?)
    # ログインできる
    post :login, :user => {:login => 'new_user', :password => 'testtest'}
    assert_redirected_to :controller => 'deals', :action => 'index'
  end
  

  # --------- ↓もともとあったもの

#  def test_Admin
#    get :Admin
#    assert_response :success
#    assert_template 'Admin'
#  end
#
#  def test_index
#    get :index
#    assert_response :success
#    assert_template 'list'
#  end
#
#  def test_list
#    get :list
#
#    assert_response :success
#    assert_template 'list'
#
#    assert_not_nil assigns(:accounts)
#  end
#
#  def test_show
#    get :show, :id => 1
#
#    assert_response :success
#    assert_template 'show'
#
#    assert_not_nil assigns(:account)
#    assert assigns(:account).valid?
#  end
#
#  def test_new
#    get :new
#
#    assert_response :success
#    assert_template 'new'
#
#    assert_not_nil assigns(:account)
#  end
#
#  def test_create
#    num_accounts = Account.count
#
#    post :create, :account => {}
#
#    assert_response :redirect
#    assert_redirected_to :action => 'list'
#
#    assert_equal num_accounts + 1, Account.count
#  end
#
#  def test_edit
#    get :edit, :id => 1
#
#    assert_response :success
#    assert_template 'edit'
#
#    assert_not_nil assigns(:account)
#    assert assigns(:account).valid?
#  end
#
#  def test_update
#    post :update, :id => 1
#    assert_response :redirect
#    assert_redirected_to :action => 'show', :id => 1
#  end
#
#  def test_destroy
#    assert_not_nil Account.find(1)
#
#    post :destroy, :id => 1
#    assert_response :redirect
#    assert_redirected_to :action => 'list'
#
#    assert_raise(ActiveRecord::RecordNotFound) {
#      Account.find(1)
#    }
#  end
end
