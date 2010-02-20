require File.dirname(__FILE__) + '/../test_helper'

# 初期残高フラグの制御に関するテスト
class InitialBalanceTest < ActiveSupport::TestCase
  
  def setup
    @cache = accounts(:first_cache)
    @food = accounts(:first_food)
    @year = 2008
  end
  
  # 最初の取引として残高を記入するとinitial_balanceになることのテスト
  def test_add_first_balance
    ib = create_balance 2000, 4, 1
    assert ib.entry.initial_balance?
  end

  # 最初の通常取引の後、最初の残高を記入してもinitial_balanceになることのテスト
  def test_add_first_balance_after_deal
    create_deal 500, 3, 10
    ib = create_balance 2000, 4, 1
    assert ib.entry.initial_balance?
  end

  private
  # 現金の残高記入をする
  def create_balance(balance, month, day)
    Deal::Balance.create!(:summary => "", :balance => balance, :account_id => @cache.id, :user_id => @cache.user_id, :date => Date.new(@year, month, day))
  end
  
  # 現金→食費の取引記入をする
  # TODO:
  def create_deal(amount, month, day, attributes = {})
    attributes = {:summary => "#{month}/#{day}の買い物",
      :amount => amount,
      :minus_account_id => @cache.id,
      :plus_account_id => @food.id,
      :user_id => @cache.user_id, :date => Date.new(@year, month, day)}.merge(attributes)
    user_id = attributes.delete(:user_id)
    amount = attributes.delete(:amount)
    plus_account_id = attributes.delete(:plus_account_id)
    minus_account_id = attributes.delete(:minus_account_id)

    deal = Deal::General.new(attributes)
    deal.user_id = user_id
    deal.debtor_entries_attributes = [{:account_id => plus_account_id, :amount => amount}]
    deal.creditor_entries_attributes = [{:account_id => minus_account_id, :amount => amount.to_i * -1}]
    deal.save!
    deal
  end
  
end
