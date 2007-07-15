require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/expenses_controller'

# Re-raise errors caught by the controller.
class Settings::ExpensesController; def rescue_action(e) raise e end; end

class Settings::ExpensesControllerTest < Test::Unit::TestCase
  fixtures :users, "account/accounts"
  set_fixture_class  "account/accounts".to_sym => 'account/base'

  def setup
    @controller = Settings::ExpensesController.new
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

  # create を  post で呼ぶと成功する。費目「自動車費」を登録する。
  def test_create
    post :create, {:account => {:name => '自動車費', :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_not_nil User.find(1).accounts.detect{|a| a.name == '自動車費' && a.kind_of?(Account::Expense)}
    assert_nil flash[:errors]
    assert_equal "費目「自動車費」を登録しました。", flash[:notice]
  end

  # createのテスト。同じ名前がすでにあると失敗する。
  def test_create_cache
    count_before = @test_user_1.accounts(true).size
    post :create, {:account => {:name => '食費', :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_equal count_before, @test_user_1.accounts(true).size
    assert_not_nil flash[:errors]
  end

  # 削除のテスト

  # delete のテスト。成功するはず。
  def test_delete
    get :delete, {:id => 2}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_nil flash[:errors]
    assert_equal "費目「食費」を削除しました。", flash[:notice]
    assert_nil Account::Base.find(:first, :conditions => 'id = 2')
  end

  # delete のテスト。使ってから消す。失敗する。
  def test_delete_used
    d = Deal.new(:user_id => 1, :minus_account_id => 1, :plus_account_id => 2, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    get :delete, {:id => 2}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_not_nil flash[:errors]
    assert_equal [Account::UsedAccountException.new_message('費目', '食費')], flash[:errors]
    assert_not_nil Account::Expense.find(:first, :conditions => 'id = 2')
  end
  
  # [security]
  #
  # ログインユーザー以外の口座が消せないことの確認。
  def test_delete_other_users
    get :delete, {:id => 2}, {:user_id => 2}
    assert_redirected_to :action => 'index'
    assert_equal "指定された費目がみつかりません。", flash[:notice]
    assert_nil flash[:errors]
    assert_not_nil Account::Expense.find(2)
  end

end
