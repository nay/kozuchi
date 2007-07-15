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

  # create のテスト

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
    assert_equal "口座「VISA」を登録しました。", flash[:notice]
  end

  # [security]
  #
  # 異なるuser_id をパラメータで渡しても安全にクレジットカード口座「VISA」を登録することを確認する。
  def test_create_visa
    post :create, {:account => {:user_id => 2, :name => 'VISA', :type => Account::CreditCard.asset_name, :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    visa =  User.find(1).accounts.detect{|a| a.name == 'VISA' && a.kind_of?(Account::CreditCard)}
    assert_not_nil visa
    assert_equal 1, visa.user_id # ログインユーザーになる
    assert_nil flash[:errors]
    assert_equal "口座「VISA」を登録しました。", flash[:notice]
  end


  # createのテスト。同じ名前がすでにあると失敗する。
  def test_create_cache
    count_before = @test_user_1.accounts(true).size
    post :create, {:account => {:name => '現金', :type => Account::Cache.asset_name, :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_equal count_before, @test_user_1.accounts(true).size
    assert_not_nil flash[:errors]
  end

  # delete のテスト。貯金箱を消す。成功するはず。
  def test_delete
    get :delete, {:id => 10}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_nil flash[:errors]
    assert_equal "口座「貯金箱」を削除しました。", flash[:notice]
    assert_nil Account::Asset.find(:first, :conditions => 'id = 10')
  end

  # delete のテスト。貯金箱を使ってから消す。失敗する。
  def test_delete_used
    d = Deal.new(:user_id => 1, :minus_account_id => 1, :plus_account_id => 10, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    get :delete, {:id => 10}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_not_nil flash[:errors]
    assert_equal [Account::UsedAccountException.new_message('口座', '貯金箱')], flash[:errors]
    assert_not_nil Account::Asset.find(:first, :conditions => 'id = 10')
  end
  
  # [security]
  #
  # ログインユーザー以外の口座が消せないことの確認。
  def test_delete_other_users
    get :delete, {:id => 4}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_equal "指定された口座がみつかりません。", flash[:notice]
    assert_nil flash[:errors]
    assert_not_nil Account::Asset.find(4)
  end

end
