require File.dirname(__FILE__) + '/../test_helper'

class AcountTest < Test::Unit::TestCase
  fixtures :users
  fixtures :friends
  fixtures :accounts
  fixtures :account_links

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
