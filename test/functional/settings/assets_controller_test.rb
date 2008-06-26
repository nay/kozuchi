require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/assets_controller'

# Re-raise errors caught by the controller.
class Settings::AssetsController; def rescue_action(e) raise e end; end

class Settings::AssetsControllerTest < Test::Unit::TestCase
#  fixtures :users, "account/accounts"
#  set_fixture_class  "account/accounts".to_sym => 'account/base'

  def setup
    @controller = Settings::AssetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # index のテスト
  def test_index
    get :index, {}, {:user_id => users(:old).id}
    assert_response :success
  end

  # create のテスト

  # create を get で呼ぶと失敗する
  def test_create_by_get
    get :create, {}, {:user_id => users(:old).id}
    assert_template '/open/not_found'
  end

  # create を  post で呼ぶと成功する。クレジットカード口座「VISA」を登録する。
  def test_create
    post :create, {:account => {:name => 'VISA', :asset_name => Account::CreditCard.asset_name, :sort_key => '10'}}, {:user_id => users(:old).id}
    assert_redirected_to :action => 'index'
    assert_not_nil users(:old).accounts.detect{|a| a.name == 'VISA' && a.kind_of?(Account::CreditCard)}
    assert_nil flash[:errors]
    assert_equal "口座「VISA」を登録しました。", flash[:notice]
  end

  # [security]
  #
  # 異なるuser_id をパラメータで渡しても安全にクレジットカード口座「VISA」を登録することを確認する。
  def test_create_with_user_id
    post :create, {:account => {:user_id => users(:old2).id, :name => 'VISA', :asset_name => Account::CreditCard.asset_name, :sort_key => '10'}}, {:user_id => users(:old).id}
    assert_redirected_to :action => 'index'
    visa =  users(:old).accounts.detect{|a| a.name == 'VISA' && a.kind_of?(Account::CreditCard)}
    assert_not_nil visa
    assert_equal users(:old).id, visa.user_id # ログインユーザーになる
    assert_nil flash[:errors]
    assert_equal "口座「VISA」を登録しました。", flash[:notice]
  end


  # createのテスト。同じ名前がすでにあると失敗する。
  def test_create_cache
    count_before = @test_user_1.accounts(true).size
    post :create, {:account => {:name => '現金', :asset_name => Account::Cache.asset_name, :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_equal count_before, @test_user_1.accounts(true).size
    assert_not_nil flash[:errors]
  end
  
  # 削除のテスト

  # delete のテスト。成功するはず。
  def test_delete
    get :delete, {:id => 10}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_nil flash[:errors]
    assert_equal "口座「貯金箱」を削除しました。", flash[:notice]
    assert_nil Account::Asset.find(:first, :conditions => 'id = 10')
  end

  # delete のテスト。使ってから消す。失敗する。
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
  
  # 更新のテスト
  
  # getでは更新できないことの確認。
  def test_update_by_get
    get :update, {}, {:user_id => 1}
    assert_template '/open/not_found'
  end
  
  # 口座を１つ名前変更できることを確認。
  def test_update_one_name
    a = Account::Asset.find(7)
    post :update, {:account => {'7' => {:name => '新しい名前', :asset_name => a.asset_name, :sort_key => a.sort_key}}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    a = Account::Base.find(7)
    assert_equal '新しい名前', a.name
  end

  # [security]
  # 
  # 異なるユーザーでログインして不正に口座名を変更できないことを確認
  def test_update_one_name_by_illegal_user
    a = Account::Base.find(7)
    post :update, {:account => {'7' => {:name => '新しい名前', :asset_name => a.asset_name, :sort_key => a.sort_key}}}, {:user_id => 2}
    assert_redirected_to :action => 'index'
    a = Account::Base.find(7)
    assert_equal '銀行', a.name
  end

  # [security]
  # 
  # user_idをパラメータに指定しても他人の所有に口座を変更できないことを確認
  def test_update_one_name_with_user_id
    a = Account::Base.find(7)
    post :update, {:account => {'7' => {:user_id => 2, :name => '新しい名前', :asset_name => a.asset_name, :sort_key => a.sort_key}}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    a = Account::Base.find(7)
    assert_equal '新しい名前', a.name
    assert_equal 1, a.user_id
  end

  
  # 口座の種類を変更できることを確認。
  def test_update_one_type
    a = Account::Base.find(10)
    assert a.kind_of?(Account::Cache)
    assert_equal false, a.kind_of?(Account::Credit)
    post :update, {:account => {'10' => {:name => '貯金箱２', :asset_name => Account::Credit.asset_name, :sort_key => a.sort_key}}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    a = Account::Base.find(10)
    assert_equal '貯金箱２', a.name
    assert a.kind_of?(Account::Credit)
    assert_equal false, a.kind_of?(Account::Cache)
  end
  
  # 口座の種類を不正に変更できないことを確認。
  # 精算先口座を　Credit　にはできない。
  def test_update_one_type_invalid
    a = Account::Base.find(7)
    post :update, {:account => {'7' => {:name => '新しい名前', :asset_name => Account::Credit.asset_name, :sort_key => a.sort_key}}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    a = Account::Base.find(7)
    assert a.kind_of?(Account::BankingFacility)
    assert_equal [Account::IllegalClassChangeException.new_message('銀行', Account::Credit.asset_name)], flash[:errors]
  end

end
