require File.dirname(__FILE__) + '/../test_helper'

class DealTest < Test::Unit::TestCase
  fixtures :users
  fixtures 'account/base'.to_sym
  set_fixture_class  "account/accounts".to_sym => 'account/base'
  
  
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
    user = User.find(1)
    assert user
    
    deal = Deal.new(:summary => "おにぎり",
     :amount => "105",
     :minus_account_id => "1",
     :plus_account_id => "2",
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
    assert_equal 1, deal.account_entries[0].account_id
    assert_equal 105 * -1, deal.account_entries[0].amount
    assert_equal deal.id, deal.account_entries[0].deal_id
    assert_equal 2, deal.account_entries[1].account_id
    assert_equal 105, deal.account_entries[1].amount
    assert_equal deal.id, deal.account_entries[1].deal_id
    assert_equal 1, deal.daily_seq

    # 追加
    deal2 = Deal.new({:summary => "おにぎり", :amount => "105", :minus_account_id => "1", :plus_account_id => "2", :user_id => user.id, :date => Date.parse("2006/04/01")})
    deal2.save!

    assert_equal 2, deal2.daily_seq

    #2の前に挿入
    deal3 = Deal.new({:summary => "おにぎり", :amount => "105", :minus_account_id => "1", :plus_account_id => "2", :user_id => user.id, :date => Date.parse("2006/04/01"), :insert_before => deal2})
    deal3.save!
   
    assert_equal 2, deal3.daily_seq
   
    #dealがそのままでdeal2が3になることを確認
    deal = Deal.find(deal.id)
    assert_equal 1, deal.daily_seq
    
    deal2 = Deal.find(deal2.id)
    assert_equal 3, deal2.daily_seq

    #日付違いを追加したら新規になることを確認
    deal4 = Deal.new(:summary => "おにぎり", :amount => "105", :minus_account_id => "1", :plus_account_id => "2", :user_id => user.id, :date => Date.parse("2006/04/02"))
    deal4.save!
    assert_equal 1, deal4.daily_seq

    #日付違いによる挿入がうまくいくことを確認
    deal5 = Deal.new(:summary => "おにぎり", :amount => "105", :minus_account_id => "1", :plus_account_id => "2", :user_id => user.id, :date => Date.parse("2006/04/02"), :insert_before => deal4 )
    deal5.save!
    assert_equal 1, deal5.daily_seq
    deal4 = Deal.find(deal4.id)
    assert_equal 2, deal4.daily_seq

    
    #日付と挿入ポイントがあっていないと例外が発生することを確認
    begin
      dealx = Deal.new(:summary => "おにぎり", :amount => "105", :minus_account_id => "1", :plus_account_id => "2", :user_id => user.id, :date => Date.parse("2006/04/02"), :insert_before => deal)
      dealx.save!
      assert false
    rescue Exception
      assert true
    end

  end
  
end
