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
    user = users(:old)
    cache = accounts(:first_cache)
    food = accounts(:first_food)

    Balance.create!(:summary => "", :balance => "14000", :account_id => cache.id, :user_id => user.id, :date => Date.new(2008, 4, 30))
    assert_equal 14000, cache.balance_before(Date.new(2008, 5, 1))

    Deal.create!(:summary => "5/1の買い物", :amount => "2380", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2008/05/01"))
    assert_equal 11620, cache.balance_before(Date.new(2008, 5, 2))
    
    balance = Balance.new(:summary => "", :balance => "9000", :account_id => cache.id, :user_id => user.id, :date => Date.new(2008, 5, 3))
    balance.save!
    assert_equal 9000, cache.balance_before(Date.new(2008, 5, 4)) # 残高は9000円
    assert_equal -2620, cache.unknown_flow(Date.new(2008, 5, 1), Date.new(2008, 5, 4)) # 不明金は-2620円
    assert_equal -2620, balance.account_entries.first.amount
    
    #5/2の1000円分を思い出して記入
    Deal.create!(:summary => "5/2の買い物", :amount => "1000", :minus_account_id => cache.id, :plus_account_id => food.id, :user_id => user.id, :date => Date.parse("2008/05/02"))
    assert_equal 9000, cache.balance_before(Date.new(2008, 5, 4)) # 残高は9000円のまま
    assert_equal -1620, cache.unknown_flow(Date.new(2008, 5, 1), Date.new(2008, 5, 4)) # 不明金は-1620円
    assert_equal -1620, balance.account_entries.first.amount
    
  end
end
