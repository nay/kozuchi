require File.dirname(__FILE__) + '/../test_helper'

class WelcomeControllerTest < ActionController::TestCase

  # ログインしていない状態のウェルカムページ
  def test_index_without_login
    get :index
    
    assert_response :success
    
    # ログインフォームがあること
    assert_tag :input, :attributes => {:id => 'login'}
  end
  
  def test_index_with_login
    get :index, nil, :user_id => users(:quentin).id
    assert_response :success
    
    # ログインフォームがないこと
    assert_no_tag :input, :attributes => {:id => 'login'}
  end
end
