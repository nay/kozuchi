require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  # account.types_in が正しく動作することのテスト
  def test_accounts_types_in
    assert_equal 4, @test_user_1.accounts.types_in(:asset).size
    assert_equal 0, @test_user_1.accounts.types_in.size
    assert_equal 5, @test_user_1.accounts.types_in(:asset, :expense).size
  end
  
  def test_accounts_asset_types_in
    assert_equal 1, @test_user_1.accounts.asset_types_in(:cache).size
    assert_equal 1, @test_user_1.accounts.asset_types_in(:banking_facility).size
    assert_equal 2, @test_user_1.accounts.asset_types_in(:cache, :credit).size
  end

end
