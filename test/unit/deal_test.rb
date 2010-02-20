require File.dirname(__FILE__) + '/../test_helper'

class DealTest < ActiveSupport::TestCase
  
  # 取引保存時に、daily_seq が正しくつくことのテスト
  def test_daily_seq
    Deal::General.delete_all
    
    deal = create_deal(105, 4, 1)
    assert_equal 1, deal.daily_seq
    deal.reload
    assert_equal 1, deal.daily_seq

    # 追加
    deal2 = create_deal(105, 4, 1)

    assert_equal 2, deal2.daily_seq
    deal2.reload
    assert_equal 2, deal2.daily_seq
    

    #2の前に挿入
    deal3 = create_deal(105, 4, 1, :insert_before => deal2)
   
    assert_equal 2, deal3.daily_seq
   
    #dealがそのままでdeal2が3になることを確認
    deal.reload
    assert_equal 1, deal.daily_seq
    
    deal2.reload
    assert_equal 3, deal2.daily_seq

    #日付違いを追加したら新規になることを確認
    deal4 = create_deal(105, 4, 2) 
    assert_equal 1, deal4.daily_seq

    #日付違いによる挿入がうまくいくことを確認
    deal5 = create_deal(105, 4, 2, :insert_before => deal4)
    assert_equal 1, deal5.daily_seq
    deal4.reload
    assert_equal 2, deal4.daily_seq
    
    #日付と挿入ポイントがあっていないと例外が発生することを確認
    assert_raise(RuntimeError) do
      create_deal(105, 4, 2, :insert_before => deal) # Deal::General.new(:summary => "おにぎり", :amount => "105", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2006/04/02"), :insert_before => deal)
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
    assert_equal 320000, balance.entries.first.amount
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
    d.confirm!
    b.reload
    assert_equal 3800, b.amount
    assert_equal 2000, balance_before(5, 12)
  end
  
  # 残高記入が削除できることのテスト
  def test_destroy_balance
    b1 = create_balance(2000, 5, 12)
    b1 = Deal::Balance.find(b1.id)
    b2 = create_balance(2000, 5, 14)
    b2 = Deal::Balance.find(b2.id)
    b2.destroy
    b1.destroy
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
    Deal::Balance.create!(:summary => "", :balance => balance, :account_id => @cache.id, :user_id => @user.id, :date => Date.new(@year, month, day))
  end
  
  # 現金→食費の取引記入をする
  def create_deal(amount, month, day, attributes = {})
    attributes = {:summary => "#{month}/#{day}の買い物",
#      :amount => amount,
#      :minus_account_id => @cache.id,
#      :plus_account_id => @food.id,
      :debtor_entries_attributes => [{:account_id => @food.id, :amount => amount}],
      :creditor_entries_attributes => [{:account_id => @cache.id, :amount => amount.to_i * -1}],
      :user_id => @user.id, :date => Date.new(@year, month, day)}.merge(attributes)
    user_id = attributes.delete(:user_id)
    deal = Deal::General.new(attributes)
    deal.user_id = user_id
    deal.save!
    deal
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
