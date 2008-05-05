require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../app/helpers/application_helper'

class UserTest < Test::Unit::TestCase
#  fixtures :users, "account/accounts", :preferences
#  set_fixture_class  "account/accounts".to_sym => 'account/base'
  include ApplicationHelper
  
  # account.types_in が正しく動作することのテスト
  def test_accounts_types_in
    assert_equal 5, users(:test_user_1).accounts.types_in(:asset).size
    assert_equal 0, users(:test_user_1).accounts.types_in.size
    assert_equal 6, users(:test_user_1).accounts.types_in(:asset, :expense).size
    assert_equal 2, users(:test_user_1).accounts.types_in(:cache).size
    assert_equal 1, users(:test_user_1).accounts.types_in(:banking_facility).size
    assert_equal 3, users(:test_user_1).accounts.types_in(:cache, :credit).size
  end
  
  def test_account_options
    options = account_options(users(:test_user_1), :asset)
    assert_not_nil options.match(/<optgroup label='口座'>/)
  end

  def test_default_asset
    user = users(:test_user_1)
    assert_not_nil user.default_asset
    assert_equal 1, user.default_asset.id
  end
  
  def test_available_asset_types
    assert_equal 4, users(:test_user_1).available_asset_types.size
    assert_equal 5, users(:test_user_2).available_asset_types.size
  end
  
end
