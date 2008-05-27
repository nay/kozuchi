require File.dirname(__FILE__) + '/../test_helper'
#require File.dirname(__FILE__) + '/../../app/helpers/application_helper'

# カスタマイズ部分に関するテスト
class OriginalUserTest < ActiveSupport::TestCase
#  include ApplicationHelper

  # 旧ユーザーでログインできることの確認
  def test_old_user_can_login
    user = User.authenticate('old', 'testtest')
    assert_not_nil user
    # ログイン後はtypeが変更されている
    assert user.instance_of?(User)
    # さらにログインできる
    user = User.authenticate('old', 'testtest')
  end
  
  # 旧ユーザーのパスワードを変更すると新方式に移行することの確認
  def test_change_old_users_password
    user = users(:old)
    user.change_password('newpass', 'newpass')
    user = User.find(user.id)
    assert user.instance_of?(User)
    assert !user.crypted_password != '6974f285f7139debe5ae317322cd585399989878'
    assert_not_nil User.authenticate('old', 'newpass')
  end
  
  # ほかの属性といっしょにパスワードを変更しても新方式に移行することの確認
  def test_change_old_users_password_with_attributes
    user = users(:old)
    user.update_attributes_with_password({:login => 'Tom'}, 'newpass', 'newpass')
    user = User.find(user.id)
    assert_equal 'Tom',user.login
    assert !user.kind_of?(LoginEngineUser)
    assert !user.crypted_password != '6974f285f7139debe5ae317322cd585399989878'
    assert_not_nil User.authenticate('Tom', 'newpass')
  end
  
  # ほかの属性といっしょにパスワードを変更するメソッドを呼んでも、パスワードに変更がなければ新方式に移行しないことの確認
  def test_update_old_users_attributes_without_password
    user = users(:old)
    user.update_attributes_with_password({:login => 'Tom'}, nil, nil)
    user = User.find(user.id)
    assert_equal 'Tom',user.login
    assert user.kind_of?(LoginEngineUser)
    assert user.crypted_password, '6974f285f7139debe5ae317322cd585399989878'
    assert_not_nil User.authenticate('Tom', 'testtest')
  end

  # ほかの属性といっしょにパスワードを変更するメソッドを呼んでも、検証エラーになれば新方式に移行しないことの確認
  def test_update_old_users_attributes_with_password_error
    user = users(:old)
    user.update_attributes_with_password({:login => 'Tom'}, 'newpass', 'wrongconfirm')
    user = User.find(user.id)
    assert_not_equal 'Tom',user.login
    assert user.kind_of?(LoginEngineUser)
    assert user.crypted_password, '6974f285f7139debe5ae317322cd585399989878'
    assert_not_nil User.authenticate('old', 'testtest')
  end
  
  # 最新クラスをアップグレードしても何も起きないことの確認
  def test_upgrade_user
    user = users(:quentin)
    updated_at = user.updated_at
    user.upgrade!('test')
    user = User.find(user.id)
    assert user.instance_of?(User)
    assert updated_at, user.updated_at
    assert_not_nil User.authenticate('quentin', 'test')
  end

  # LoginEngineUserをアップグレードするテスト
  def test_upgrade_login_engine_user
    user = users(:old)
    user.upgrade!('testtest')
    user = User.find(user.id)
    assert user.instance_of?(User)
    assert_not_nil User.authenticate('old', 'testtest')
  end

  # account.types_in が正しく動作することのテスト
  def test_accounts_types_in
    assert_equal 5, users(:old).accounts.types_in(:asset).size
    assert_equal 0, users(:old).accounts.types_in.size
    assert_equal 6, users(:old).accounts.types_in(:asset, :expense).size
    assert_equal 2, users(:old).accounts.types_in(:cache).size
    assert_equal 1, users(:old).accounts.types_in(:banking_facility).size
    assert_equal 3, users(:old).accounts.types_in(:cache, :credit).size
  end
  
#  def test_account_options
#    options = account_options(users(:test_user_1), :asset)
#    assert_not_nil options.match(/<optgroup label='口座'>/)
#  end
#
  def test_default_asset
    user = users(:old)
    assert_not_nil user.default_asset
    assert_equal 1, user.default_asset.id
  end

  def test_available_asset_types
    assert_equal 4, users(:old).available_asset_types.size
    assert_equal 5, users(:old2).available_asset_types.size
  end
  
end
