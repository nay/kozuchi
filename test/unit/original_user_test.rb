require File.dirname(__FILE__) + '/../test_helper'
#require File.dirname(__FILE__) + '/../../app/helpers/application_helper'

# カスタマイズ部分に関するテスト
class OriginalUserTest < ActiveSupport::TestCase
#  include ApplicationHelper

  # 旧ユーザーでログインできることの確認
  def test_old_user_can_login
    user = User.authenticate('old', 'testtest')
    assert_not_nil user
    assert 'old', user.login
  end
  
  # 旧ユーザーのパスワードを変更すると新方式に移行することの確認
  def test_change_old_users_password
    assert true # TODO
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
