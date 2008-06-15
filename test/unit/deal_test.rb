require File.dirname(__FILE__) + '/../test_helper'

class DealTest < Test::Unit::TestCase
#  fixtures :users
#  fixtures 'account/accounts'.to_sym
  set_fixture_class  :accounts => Account::Base
  
  
  # 借方、貸方の entry が正しくとれることのテスト
#  def test_left_right_entry
#    user = User.find(1)
#    assert user
#    # 現金から食費へ
#    deal = Deal.new(:summary => "おにぎり",
#     :amount => "105",
#     :minus_account_id => "1",
#     :plus_account_id => "2",
#     :user_id => user.id
#    )
#    deal.date = Date.parse("2006/04/01");
#    deal.save!
#    assert_equal(1, deal.debtor_entries.size)
#    assert_equal 2, deal.debtor_entries[0].account_id # 費用が増えた＝借方
#    assert_equal 1, deal.creditor_entries[0].account_id # 現金が減った＝貸方
#  end

  # 取引保存時に、daily_seq が正しくつくことのテスト
  def test_daily_seq
    Deal.delete_all
    user = users(:old)
    assert user
    
    cache = accounts(:first_cache)
    food = accounts(:first_food)
    
    deal = Deal.new(:summary => "おにぎり",
     :amount => "105",
     :minus_account_id => cache.id,
     :plus_account_id => food.id,
     :user_id => user.id
    )
    deal.date = Date.parse("2006/04/01");
    deal.save!

    deal = Deal.find(deal.id)
    assert deal
    assert_equal user.id, deal.user_id
    assert_equal "おにぎり", deal.summary
    assert_equal 4, deal.date.month
    assert_equal 2006, deal.date.year
    assert_equal 2, deal.account_entries.size
    assert_equal cache.id, deal.account_entries[0].account_id
    assert_equal 105 * -1, deal.account_entries[0].amount
    assert_equal deal.id, deal.account_entries[0].deal_id
    assert_equal food.id, deal.account_entries[1].account_id
    assert_equal 105, deal.account_entries[1].amount
    assert_equal deal.id, deal.account_entries[1].deal_id
    assert_equal 1, deal.daily_seq

    # 追加
    deal2 = Deal.new({:summary => "おにぎり", :amount => "105", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2006/04/01")})
    deal2.save!

    assert_equal 2, deal2.daily_seq

    #2の前に挿入
    deal3 = Deal.new({:summary => "おにぎり", :amount => "105", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2006/04/01"), :insert_before => deal2})
    deal3.save!
   
    assert_equal 2, deal3.daily_seq
   
    #dealがそのままでdeal2が3になることを確認
    deal = Deal.find(deal.id)
    assert_equal 1, deal.daily_seq
    
    deal2 = Deal.find(deal2.id)
    assert_equal 3, deal2.daily_seq

    #日付違いを追加したら新規になることを確認
    deal4 = Deal.new(:summary => "おにぎり", :amount => "105", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2006/04/02"))
    deal4.save!
    assert_equal 1, deal4.daily_seq

    #日付違いによる挿入がうまくいくことを確認
    deal5 = Deal.new(:summary => "おにぎり", :amount => "105", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2006/04/02"), :insert_before => deal4 )
    deal5.save!
    assert_equal 1, deal5.daily_seq
    deal4 = Deal.find(deal4.id)
    assert_equal 2, deal4.daily_seq

    
    #日付と挿入ポイントがあっていないと例外が発生することを確認
    begin
      dealx = Deal.new(:summary => "おにぎり", :amount => "105", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2006/04/02"), :insert_before => deal)
      dealx.save!
      assert false
    rescue Exception
      assert true
    end

  end

  # 4/30 に残高、5/1 に取引、5/3に残高、5/2に取引という順序で記入したとき、残高計算・不明金計算が正しく動作することのテスト
  def test_balance
    create_balance(14000, 4, 30)                # 4/30 に残高 14000を記入
    assert_equal 14000, balance_before(5, 1)    # 5/1 の残高 14000 
    assert_equal 0, unknown_flow(4, 30, 5, 1)   # 4/30〜5/1の不明金 0

    create_deal(2380, 5, 1)                     # 5/1 に取引 -2380を記入
    assert_equal 11620, balance_before(5, 2)    # 5/2 の残高 11620
    
    create_balance(9000, 5, 3)                  # 5/3 に残高 9000を記入
    assert_equal 9000, balance_before(5, 4)     # 5/4 の残高 9000
    assert_equal -2620, unknown_flow(5, 1, 5, 4)# 5/1〜5/4の不明金は、9000 - 11620 で -2620
    
    #5/2の1000円分を思い出して記入
    create_deal(1000, 5, 2)
    assert_equal 9000, balance_before(5, 4) # 残高は9000円のまま
    assert_equal -1620, unknown_flow(5, 1, 5, 4) # 不明金は-1620円
   
    #5/10に3000円の買い物
    deal_3000 = create_deal(3000, 5, 10)
    assert_equal 6000, balance_before(5, 11)
    
    #同じ日に残高記入
    create_balance(7000, 5, 10)
    assert_equal 7000, balance_before(5, 11)
    assert_equal -620, unknown_flow(5, 1, 5, 11)
    
    #さらに記入しても不明金はかわらない
    create_deal(500, 5, 10)
    assert_equal 6500, balance_before(5, 11)
    assert_equal -620, unknown_flow(5, 1, 5, 11)
        
    # 5/10の3000円の買い物を削除しても、5/11以前の残高は変わらない
    deal_3000.destroy
    assert_equal 6500, balance_before(5, 11)
    # 不明金は大きくなる
    assert_equal -3620, unknown_flow(5, 1, 5, 11)
  end
  
  # 「最初の残高確認」以前の残高についてファジーに処理するテスト
  def test_initial_balance
    # 2008/5/1 に残高を記入して、4月末時点での残高を照合すると、同じ残高となる
    balance = create_balance(320000, 5, 1)
    assert_equal 320000, balance.account_entries.first.amount
    assert_equal 320000, balance_before(5, 2)
    assert_equal 320000, balance_before(5, 1)
    # 5/1〜5/2の間の不明金は0
    assert_equal 0, unknown_flow(5, 1, 5, 3)
    
    # 2008/4/15 に取引を記入すると、3月末時点での残高は増える
    create_deal(700, 4, 15)
    assert_equal 320700, balance_before(3, 31)
  end
  
  def test_confirm
    # 5/10に未確認取引
    d = create_deal(1800, 5, 10, :confirmed => false)
    assert_equal 0, balance_before(5, 11)
    # 5/12に残高記入
    b = create_balance(2000, 5, 12)
    assert_equal 2000, b.amount
    assert_equal 2000, balance_before(5, 12)
    # 5/10の取引を確認する
    d.confirm
    b.reload
    assert_equal 3800, b.amount
    assert_equal 2000, balance_before(5, 12)
  end
  
  # ------------------  set_up  ----------------------
  def setup
    @user = users(:old)
    @cache = accounts(:first_cache)
    @food = accounts(:first_food)
    @year = 2008
  end
  
  
  private
  # --------------------- helpers -----------------------
  
  # 現金の残高記入をする
  def create_balance(balance, month, day)
    Balance.create!(:summary => "", :balance => balance, :account_id => @cache.id, :user_id => @user.id, :date => Date.new(@year, month, day))
  end
  
  # 現金→食費の取引記入をする
  def create_deal(amount, month, day, attributes = {})
    attributes = {:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => @cache.id, :plus_account_id => @food.id, :user_id => @user.id, :date => Date.new(@year, month, day)}.merge(attributes)
    Deal.create!(attributes)
  end
  
  # 残高を取得する
  def balance_before(month, day, account = nil)
    account ||= @cache
    account.balance_before(Date.new(@year, month, day))
  end
  
  # 不明金を取得する
  def unknown_flow(from_month, from_day, to_month, to_day, account = nil)
    account ||= @cache
    account.unknown_flow(Date.new(@year, from_month, from_day), Date.new(@year, to_month, to_day))
  end
end
