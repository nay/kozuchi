require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/assets_controller'

# Re-raise errors caught by the controller.
class Settings::AssetsController; def rescue_action(e) raise e end; end

class Settings::AssetsControllerTest < Test::Unit::TestCase
  fixtures :users, "account/accounts"
  set_fixture_class  "account/accounts".to_sym => 'account/base'

  def setup
    @controller = Settings::AssetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # index のテスト
  def test_index
    get :index, {}, {:user_id => 1}
    assert_response :success
  end

  # create を get で呼ぶと失敗する
  def test_create_by_get
    get :create, {}, {:user_id => 1}
    assert_template '/open/not_found'
  end

  # create を  post で呼ぶと成功する。クレジットカード口座「VISA」を登録する。
  def test_create_visa
    post :create, {:account => {:name => 'VISA', :type => Account::CreditCard.asset_name, :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_not_nil User.find(1).accounts.detect{|a| a.name == 'VISA' && a.kind_of?(Account::CreditCard)}
    assert_nil flash[:errors]
  end

  # createのテスト。同じ名前がすでにあると失敗する。
  def test_create_cache
    post :create, {:account => {:name => '現金', :type => Account::Cache.asset_name, :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_equal ['で名前が重複しています。'], flash[:errors]
  end

end
