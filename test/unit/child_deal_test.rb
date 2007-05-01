require File.dirname(__FILE__) + '/../test_helper'

class ChildDealTest < Test::Unit::TestCase
  fixtures :users
  fixtures :accounts
  fixtures :account_rules

  # 精算ルールがあるとき、従属行が新しく作られ、更新時は作り直されることをテストする
  def test_create
    deal = Deal.new(:user_id => 1, :summary => 'カードで食事', :minus_account_id => @first_credit_card.id, :plus_account_id => @first_food.id, :amount => 3200, :date => Date.today)
    deal.save!
    assert_equal 1, deal.children.size
    child = deal.children[0]
    assert_equal @first_credit_card.id, child.debtor_entries[0].account_id # 負債の減少・・借方
    assert_equal @first_bank.id, child.creditor_entries[0].account_id # 資産の減少・・貸方
    next_month = Date.today >> 1
    assert_equal next_month.month, child.date.month
    
    old_child_id = child.id
    
    deal = Deal.find(deal.id)
    deal.amount = 3500
    deal.save!
    
    assert_equal 1, deal.children.size
    assert old_child_id != deal.children[0].id
    assert_equal 3500, deal.amount
    
    assert_nil Deal.find(:first, :conditions => "id = #{old_child_id}")
  end
  
  def setup
    Deal.delete_all
  end
  
end
