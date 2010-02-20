require File.dirname(__FILE__) + '/../test_helper'

# Userオブジェクトの残高・移動系メソッドの動作を確認するテスト
class UserBalanceFlowTest < ActiveSupport::TestCase
  set_fixture_class  :accounts => Account::Base
  
  # ------------------  set_up  ----------------------
  def setup
    # ユーザー
    @first_user = users(:old)
    @second_user = users(:old2)

    # 資産
    @cache = accounts(:first_cache)
    @bank = accounts(:first_bank)
    # 支出
    @food = accounts(:first_food)
    @house = accounts(:first_house)
    # 収入
    @saraly = accounts(:first_saraly)
    @bonus = accounts(:first_bonus)
    # 年
    @year = 2008
    
    
    @second_cache = accounts(:second_cache)
    @second_food = accounts(:second_food)
  end

  # -------- Test Cases -----------
  
  # １つの口座についてbalance_sum, balances が正しいことを確認する
  def test_balance
    # 現金
    # 3/20 食費 500
    # 3/31 残高 4000
    # 4/1  食費 300
    # 4/30 残高 1000 （不明金 2700）
    create_deal 3, 20, @cache, @food, 500
    assert_equal -500, balance_sum(@first_user, 3, 21, "accounts.type != 'Income' and accounts.type != 'Expense'")

    ib = create_balance 3, 31, @cache, 4000
    assert_equal 4000, balance_sum(@first_user, 3, 21, "accounts.type != 'Income' and accounts.type != 'Expense'")
    assert_equal 4000, balance_sum(@first_user, 3, 31, "accounts.type != 'Income' and accounts.type != 'Expense'")

    assert ib.entries.first.initial_balance?
    
    create_deal 4, 1, @cache, @food, 300
    create_balance 4, 30, @cache, 1000
    
    # 3/1の資産合計は4500、現金残高も4500
    assert_equal 4500, balance_sum(@first_user, 3, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")
    
    # 5/1の資産残高合計は1000
    assert_equal 1000, balance_sum(@first_user, 5, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")
  end

  # １つの口座について、初期残高が変更になるケースでbalance_sum, balances が正しいことを確認する
  def test_balance_with_initial_change
    # 現金
    # 3/20 食費 500
    # 3/31 残高 4000
    # 4/1  食費 300
    #
    # ここに、3/19 残高 0を足す。
    #
    # 3/19  残高 0
    # 3/20 食費 500 (残高-500)
    # 3/31 残高 4000 (残高4000)
    # 4/1  食費 300  (残高3700)
    create_deal 3, 20, @cache, @food, 500
    ib = create_balance 3, 31, @cache, 4000
    assert ib.entries.first.initial_balance?

    create_deal 4, 1, @cache, @food, 300

    ib2 = create_balance 3, 19, @cache, 0
    assert ib2.entries.first.initial_balance?
    ib.reload
    assert_equal false, ib.entries.first.initial_balance?

    # 3/1の資産合計は0
    assert_equal 0, balance_sum(@first_user, 3, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")

    # 5/1の資産残高合計は3700
    assert_equal 3700, balance_sum(@first_user, 5, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")
  end

  # １つの口座について、残高の更新によって初期残高が変更になるケースでbalance_sum, balances が正しいことを確認する
  def test_balance_with_initial_change
    # 現金
    # 3/20 食費 500
    # 3/31 残高 4000
    # 4/1  食費 300
    # 4/20 残高 1000
    #
    # このあと、4/20の残高を3/19に変更する
    #   3/19 残高 1000  amount 1000
    #   3/20 食費 500  残高500
    #   3/31 残高 4000 amount 3500
    #   4/1  食費 300  残高3700
    #
    create_deal 3, 20, @cache, @food, 500
    ib = create_balance 3, 31, @cache, 4000
    assert ib.entries.first.initial_balance?

    create_deal 4, 1, @cache, @food, 300

    ib2 = create_balance 4, 20, @cache, 1000

    new_date = (ib2.date << 1) - 1
    ib2.date = new_date
    ib2.save!

    assert_equal true, ib2.entries.first.initial_balance?
    assert_equal 1000, ib2.amount

    ib.reload
    assert_equal ib2.date, ib2.entry.date
    assert_equal false, ib.entries.first.initial_balance?
    assert_equal 3500, ib.amount

    # 3/1の資産合計は1000
    assert_equal 1000, balance_sum(@first_user, 3, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")

    # 5/1の資産残高合計は3700
    assert_equal 3700, balance_sum(@first_user, 5, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")
  end

  # 複数の口座についての残高が正しいことを確認する
  def test_balance_in_multi_accounts
    # 3/1 銀行→食費 1000
    # 3/3 銀行残高 4000
    # 3/5 現金残高 3000
    # 3/6 現金→食費 500
    create_deal 3, 1, @bank, @food, 1000
    create_balance 3, 3, @bank, 4000
    create_balance 3, 5, @cache, 3000
    create_deal 3, 6, @cache, @food, 500
    # 2/28時点では合計8000、現金3000、銀行5000となっている
    assert_equal 8000, balance_sum(@first_user, 2, 28)
    assert_equal 3000, balance(@first_user, 2, 28, @cache)
    assert_equal 5000, balance(@first_user, 2, 28, @bank)
    # 3/10時点では合計6500、現金2500、銀行4000となっている
    assert_equal 6500, balance_sum(@first_user, 3, 10)
    assert_equal 2500, balance(@first_user, 3, 10, @cache)
    assert_equal 4000, balance(@first_user, 3, 10, @bank)
  end
  
  # 複数のユーザーについての残高が正しく、balancesに他人のものが含まれないことを確認する
  def test_balance_in_multil_user
    create_deal 3, 1, @bank, @food, 1000
    create_balance 3, 3, @bank, 4000
    create_deal 3, 1, @second_cache, @second_food, 1000
    create_balance 3, 3, @second_cache, 2000
    
    assert_equal 4000, balance(@first_user, 3, 4, @bank)
    assert_equal 2000, balance(@second_user, 3, 4, @second_cache)
    
    assert_nil @first_user.accounts.balances(Date.new(@year, 3, 4)).detect{|a| a.user_id != @first_user.id}
    assert_nil @second_user.accounts.balances(Date.new(@year, 3, 4)).detect{|a| a.user_id != @second_user.id}
  end

  # flow_sum, flows が正しいことを確認する
  def test_flows
    create_balance 4, 1, @cache, 10000        # 4/1 現金残高 10000（初期）
    create_balance 4, 1, @bank, 250000        # 4/1 銀行残高 250,000（初期）
    create_deal 4, 1, @cache, @food, 1000     # 4/1 現金→食費 1000
    create_deal 4, 2, @bank, @house, 120000   # 4/2 銀行→住居費 120,000 (銀行残高 130,000)
    create_deal 4, 3, @bank, @food, 5000      # 4/3 銀行→食費 5000      (銀行残高 125,000)
    create_deal 4, 4, @cache, @house, 3000    # 4/4 現金→住居費 3000
    create_balance 4, 5, @cache, 5000         # 4/5 現金残高 5000（不明金 支出1000）
    create_deal 4, 6, @saraly, @bank, 200000  # 4/6 給料 → 銀行 200,000  (銀行残高 325,0000
    create_deal 4, 10, @bonus, @bank, 300000  # 4/10 ボーナス → 銀行 300,000 (銀行残高 625,000)
    create_balance 4, 20, @bank, 800000       # 4/20 銀行残高 800,000（不明金 収入175,000） 
    # 支出合計は 1,000 + 120,000 + 5,000 + 3,000 + 1,000 = 130,000
    assert_equal 130000, expense_sum(@first_user, 4)
    # 食費合計は 1000 + 5000 = 6000
    assert_equal 6000, flow(@first_user, 4, @food)
    # 住居費合計は 120,000 + 3000 = 123,000
    assert_equal 123000, flow(@first_user, 4, @house)
    # 給料合計は -200,000
    assert_equal -200000, flow(@first_user, 4, @saraly)
    # 不明金（現金）は 1000
    assert_equal 1000, unknown(@first_user, 4, @cache)
    # 不明金（銀行）は -175000
    assert_equal -175000, unknown(@first_user, 4, @bank)

    # 収入合計は、200,000 + 300,000 + 175,000 = 675,000
    assert_equal -675000, income_sum(@first_user, 4)
  end

  # 複数のユーザーについてのフローが正しく、flowsに他人のものが含まれないことを確認する
  def test_flow_in_multil_user
    create_deal 3, 1, @bank, @food, 1000
    create_balance 3, 3, @bank, 4000
    create_balance 3, 4, @bank, 2000
    create_deal 3, 1, @second_cache, @second_food, 1500
    create_balance 3, 3, @second_cache, 2000
    create_balance 3, 4, @second_cache, 1000
    
    assert_equal 1000, flow(@first_user, 3, @food)
    assert_equal 2000, unknown(@first_user, 3, @bank)
    assert_equal 1500, flow(@second_user, 3, @second_food)
    assert_equal 1000, unknown(@second_user, 3, @second_cache)
    
    assert_nil @first_user.accounts.flows(*date_range(3)).detect{|a| a.user_id != @first_user.id}
    assert_nil @second_user.accounts.flows(*date_range(3)).detect{|a| a.user_id != @second_user.id}
  end

  private
  # TODO
  def create_deal(month, day, from, to, amount)
    attributes = {:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id, :user_id => to.user_id, :date => Date.new(@year, month, day)}
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
  
  def create_balance(month, day, account, balance)
    Deal::Balance.create!(:summary => "", :balance => balance, :account_id => account.id, :user_id => account.user_id, :date => Date.new(@year, month, day))
  end
  
  def balance_sum(user, month, day, conditions = "accounts.type != 'Income' and accounts.type != 'Expense'")
    user.accounts.balance_sum(Date.new(@year, month, day), conditions)
  end
  
  def balance(user, month, day, account)
    balances = user.accounts.balances(Date.new(@year, month, day))
    balances.detect{|a| a.id == account.id}.balance
  end
  
  def income_sum(user, month)
    user.accounts.income_sum(*date_range(month))
  end

  def expense_sum(user, month)
    user.accounts.expense_sum(*date_range(month))
  end
  
  def flow(user, month, account)
    flows = user.accounts.flows(*date_range(month))
    flows.detect{|a| a.id == account.id}.flow
  end
  
  def unknown(user, month, account)
    unknowns = user.accounts.unknowns(*date_range(month))
    unknowns.detect{|a| a.id == account.id}.unknown
  end
    
  def date_range(month)
    start_date = Date.new(@year, month, 1)
    end_date = start_date >> 1
    return [start_date, end_date]
  end
end