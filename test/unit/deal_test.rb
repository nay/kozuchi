require File.dirname(__FILE__) + '/../test_helper'

class DealTest < Test::Unit::TestCase
#  fixtures :deals
  fixtures :accounts
  fixtures :users

  def test_create_simple
    user = User.find(1)
    assert user
    deal = Deal.create_simple(
      user.id,
      Time.parse("2006/04/01"), "‚¨‚É‚¬‚è",
      105,
      1,
      2)

    deal = Deal.find(1)
    assert deal
    assert_equal user.id, deal.user_id
    assert_equal "‚¨‚É‚¬‚è", deal.summary
    assert_equal 4, deal.date.month
    assert_equal 2006, deal.date.year
    assert_equal 2, deal.account_entries.size
    assert_equal deal.account_entries[0].account_id, 1
    assert_equal deal.account_entries[0].amount, -105
    assert_equal deal.account_entries[0].deal_id, 1
    assert_equal deal.account_entries[1].account_id, 2
    assert_equal deal.account_entries[1].amount, 105
    assert_equal deal.account_entries[1].deal_id, 1
  end
end
