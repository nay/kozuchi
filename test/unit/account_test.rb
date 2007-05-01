require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < Test::Unit::TestCase
  self.use_instantiated_fixtures  = false
  fixtures :users
  fixtures :friends
  fixtures :accounts
  fixtures :account_links

  def test_name_with_asset_type
    assert_equal '現金(現金)', Account.find(1).name_with_asset_type
    assert_equal '食費(支出)', Account.find(2).name_with_asset_type
    assert_equal 'ボーナス(収入)', Account.find(8).name_with_asset_type
  end

  # tests partner account error
  def test_wrong_partner_account
    account = Account.find(1)
    wrong_partner_account = Account.find(4)
    account.partner_account_id = wrong_partner_account.id
    is_error = false
    begin
      account.save!
    rescue
      is_error = true
    end
    assert is_error
  end
end
