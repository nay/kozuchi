require File.dirname(__FILE__) + '/../test_helper'

# Userオブジェクトの残高・移動系メソッドの動作を確認するテスト
class UserBalanceFlowTest < Test::Unit::TestCase
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
    ib = create_balance 3, 31, @cache, 4000
    assert ib.account_entries.first.initial_balance?
    
    create_deal 4, 1, @cache, @food, 300
    create_balance 4, 30, @cache, 1000
    
    # 3/1の資産合計は4500、現金残高も4500
    assert_equal 4500, balance_sum(@first_user, 3, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")
    
    # 5/1の資産残高合計は1000
    assert_equal 1000, balance_sum(@first_user, 5, 1, "accounts.type != 'Income' and accounts.type != 'Expense'")
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

  private
  def create_deal(month, day, from, to, amount)
    attributes = {:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id, :user_id => to.user_id, :date => Date.new(@year, month, day)}
    Deal.create!(attributes)
  end
  
  def create_balance(month, day, account, balance)
    Balance.create!(:summary => "", :balance => balance, :account_id => account.id, :user_id => account.user_id, :date => Date.new(@year, month, day))
  end
  
  def balance_sum(user, month, day, conditions = "accounts.type != 'Income' and accounts.type != 'Expense'")
    user.accounts.balance_sum(Date.new(@year, month, day), conditions)
  end
  
  def balance(user, month, day, account)
    balances = user.accounts.balances(Date.new(@year, month, day))
    balances.detect{|a| a.id == account.id}.balance
  end
  
end