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

  def test_dummy
    assert true
  end


#  # index のテスト
#  def test_index
#    get :index, {}, {:user_id => 1}
#    assert_response :success
#  end

#  # create を get で呼ぶと失敗する
#  def test_create_by_get
#    get :create, {}, {:user_id => 1}
#    assert_template '/open/not_found'
#  end
#
#  # create を  post で呼ぶと成功する。費目「自動車費」を登録する。
#  def test_create
#    post :create, {:account => {:name => '自動車費', :sort_key => '10'}}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    assert_not_nil User.find(1).accounts.detect{|a| a.name == '自動車費' && a.kind_of?(Account::Expense)}
#    assert_nil flash[:errors]
#    assert_equal "費目「自動車費」を登録しました。", flash[:notice]
#  end
#
#  # [security]
#  #
#  # 異なるuser_id をパラメータで渡しても安全に登録することを確認する。
#  def test_create_with_user_id
#    post :create, {:account => {:user_id => 2, :name => '自動車費', :asset_name => Account::CreditCard.asset_name, :sort_key => '10'}}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    new_account =  User.find(1).accounts.detect{|a| a.name == '自動車費' && a.kind_of?(Account::Expense)}
#    assert_not_nil new_account
#    assert_equal 1, new_account.user_id # ログインユーザーになる
#    assert_nil flash[:errors]
#    assert_equal "費目「自動車費」を登録しました。", flash[:notice]
#  end
#
#  # createのテスト。同じ名前がすでにあると失敗する。
#  def test_create_cache
#    count_before = @test_user_1.accounts(true).size
#    post :create, {:account => {:name => '食費', :sort_key => '10'}}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    assert_equal count_before, @test_user_1.accounts(true).size
#    assert_not_nil flash[:errors]
#  end
#
#  # 削除のテスト
#
#  # delete のテスト。成功するはず。
#  def test_delete
#    get :delete, {:id => 2}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    assert_nil flash[:errors]
#    assert_equal "費目「食費」を削除しました。", flash[:notice]
#    assert_nil Account::Base.find(:first, :conditions => 'id = 2')
#  end
#
#  # delete のテスト。使ってから消す。失敗する。
#  def test_delete_used
#    d = Deal::General.new(:user_id => 1, :minus_account_id => 1, :plus_account_id => 2, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
#    d.save!
#    get :delete, {:id => 2}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    assert_not_nil flash[:errors]
#    assert_equal [Account::Base::UsedAccountException.new_message('費目', '食費')], flash[:errors]
#    assert_not_nil Account::Expense.find(:first, :conditions => 'id = 2')
#  end
#
#  # [security]
#  #
#  # ログインユーザー以外の口座が消せないことの確認。
#  def test_delete_other_users
#    get :delete, {:id => 2}, {:user_id => 2}
#    assert_redirected_to :action => 'index'
#    assert_equal "指定された費目がみつかりません。", flash[:notice]
#    assert_nil flash[:errors]
#    assert_not_nil Account::Expense.find(2)
#  end
#
#  # 更新のテスト
#
#  # getでは更新できないことの確認。
#  def test_update_by_get
#    get :update, {}, {:user_id => 1}
#    assert_template '/open/not_found'
#  end
#
#  # 費目を１つ名前変更できることを確認。
#  def test_update_one_name
#    a = Account::Base.find(2)
#    post :update, {:account => {'2' => {:name => '新しい名前', :sort_key => a.sort_key}}}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    a = Account::Base.find(2)
#    assert_equal '新しい名前', a.name
#  end
#
#  # [security]
#  #
#  # 異なるユーザーでログインして不正に口座名を変更できないことを確認
#  def test_update_one_name_by_illegal_user
#    a = Account::Base.find(2)
#    post :update, {:account => {'2' => {:name => '新しい名前', :sort_key => a.sort_key}}}, {:user_id => 2}
#    assert_redirected_to :action => 'index'
#    a = Account::Base.find(2)
#    assert_equal '食費', a.name
#  end
#
#  # [security]
#  #
#  # user_idをパラメータに指定しても他人の所有に口座を変更できないことを確認
#  def test_update_one_name_with_user_id
#    a = Account::Base.find(2)
#    post :update, {:account => {'2' => {:user_id => 2, :name => '新しい名前', :sort_key => a.sort_key}}}, {:user_id => 1}
#    assert_redirected_to :action => 'index'
#    a = Account::Base.find(2)
#    assert_equal '新しい名前', a.name
#    assert_equal 1, a.user_id
#  end

end
