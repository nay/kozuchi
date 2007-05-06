require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../app/helpers/application_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users, "account/accounts"
  set_fixture_class  "account/accounts".to_sym => 'account/base'
  include ApplicationHelper

  # account.types_in が正しく動作することのテスト
  def test_accounts_types_in
    assert_equal 4, @test_user_1.accounts.types_in(:asset).size
    assert_equal 0, @test_user_1.accounts.types_in.size
    assert_equal 5, @test_user_1.accounts.types_in(:asset, :expense).size
    assert_equal 1, @test_user_1.accounts.types_in(:cache).size
    assert_equal 1, @test_user_1.accounts.types_in(:banking_facility).size
    assert_equal 2, @test_user_1.accounts.types_in(:cache, :credit).size
  end
  
  def test_account_options
    options = account_options(@test_user_1, :asset)
    assert_not_nil options.match(/<optgroup label='口座'>/)
  end

  def test_default_asset
    assert_not_nil @test_user_1.default_asset
    assert_equal 1, @test_user_1.default_asset.id
  end
  
  def test_available_asset_types
    assert_equal 4, assert_equal @test_user_1.available_asset_types.size
  end

end
