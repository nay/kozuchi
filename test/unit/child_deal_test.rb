require File.dirname(__FILE__) + '/../test_helper'

class ChildDealTest < Test::Unit::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :users
  fixtures 'account/accounts'.to_sym
  set_fixture_class  "account/accounts".to_sym => 'account/base'
  fixtures :account_rules

  # 精算ルールがあるとき、従属行が新しく作られ、更新時は作り直されることをテストする
  def test_create
    # なぜかuse_instantiated_fixturesが効かない
    @first_credit_card = Account::Base.find(6)
    @first_food = Account::Base.find(2)
    @first_bank = Account::Base.find(7)
    
    deal = Deal.new(:user_id => 1, :summary => 'カードで食事', :minus_account_id => @first_credit_card.id, :plus_account_id => @first_food.id, :amount => 3200, :date => Date.today)
    deal.save!
    assert_equal 1, deal.children.size
    child = deal.children(true)[0] # TODO: とりなおさないと失敗する
    assert_equal @first_credit_card.id, child.plus_account_id # 負債の減少・・借方
    assert_equal @first_bank.id, child.minus_account_id # 資産の減少・・貸方
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
