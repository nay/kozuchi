require File.dirname(__FILE__) + '/../test_helper'

class FriendDealTest < Test::Unit::TestCase
  fixtures :users
  fixtures :friends
  fixtures :accounts
  fixtures :account_links
  
  # フレンド取引のテスト
  def test_not_confirmed
    # 作成
    first_deal = Deal.new(
      :summary => 'second へ貸した',
      :amount => 1000,
      :minus_account_id => 1,
      :plus_account_id => 3,
      :user_id => 1,
      :date => Date.parse("2006/05/01")
    )
    first_deal.save!
    first_deal = Deal.find(first_deal.id)

    first_second_entry = first_deal.entry(3)
    assert first_second_entry.friend_link
    friend_link = first_second_entry.friend_link # あとでつかう
    another_entry = first_second_entry.friend_link.another(first_second_entry.id)
    assert_equal 2, another_entry.user_id 
    assert_equal 5, another_entry.account_id
    assert 1000*(-1), another_entry.amount
    
    # 相手が未確定な状態で金額を変更したら相手も変わる
    first_deal.attributes = {:amount => 1200}
    first_deal.save!

    # 以前の相手は削除されている
    assert !AccountEntry.find(:first, :conditions => "id = #{another_entry.id}")

    # 作り直されるのでとりなおす
    another_entry = first_second_entry.friend_link.another(first_second_entry.id)
    assert another_entry
    
    friend_link = first_second_entry.friend_link # あとでつかう
    assert friend_link
    friend_link_id = friend_link.id
    
    another_entry = AccountEntry.find(another_entry.id)
    assert_equal 1200*(-1), another_entry.amount 
    
    # 相手が未確定な状態で削除したら相手は消える
    first_deal.destroy
    another_entry = AccountEntry.find(:first, :conditions => "id = #{another_entry.id}")
    assert !another_entry
    assert !DealLink.find(:first, :conditions => "id = #{friend_link_id}")
    
  end
  
  def test_confirmed
    # 作成
    first_deal = Deal.new(
      :summary => 'second に借りた',
      :amount => 1000,
      :minus_account_id => 3,
      :plus_account_id => 1,
      :user_id => 1,
      :date => Date.parse("2006/05/02")
    )
    first_deal.save!
    first_deal = Deal.find(first_deal.id)

    first_second_entry = first_deal.entry(3)
    assert first_second_entry.friend_link
    friend_link_id = first_second_entry.friend_link.id # あとでつかう
    another_entry = first_second_entry.friend_link.another(first_second_entry.id)
    assert_equal 2, another_entry.user_id 
    assert_equal 5, another_entry.account_id
    assert 1000, another_entry.amount

    # 相手を確定にする
    friend_deal = another_entry.deal
    friend_deal.confirm
    
    friend_deal = another_entry.deal(true) # とりなおす
    
    assert friend_deal.confirmed
    
    assert friend_deal.entry(5).friend_link
    
    # 変更したら、新しい相手ができる。旧相手はリンクがきれる。
    first_deal.attributes = {:amount => 1200}
    first_deal.save!
    
    friend_deal = Deal.find(friend_deal.id)
    assert !friend_deal.entry(5).friend_link # リンクがきれたはず。
    
    assert !DealLink.find(:first, :conditions => "id = #{friend_link_id}")
    
    # 新しい相手ができたはず。
    first_second_entry = first_deal.entry(3)
    new_friend_link = first_second_entry.friend_link
    
    assert new_friend_link.id != friend_link_id
    new_friend_link_id = new_friend_link.id
    
    new_another_entry = new_friend_link.another(first_second_entry.id)
    
    assert new_another_entry
    assert_equal 1200, new_another_entry.amount
    
    # 新しい相手を確定にする
    new_friend_deal = new_another_entry.deal
    new_friend_deal.confirmed = true
    new_friend_deal.save!
    
    # 新しい相手を削除すると自分のリンクはきえるが自分は残る
    new_friend_deal.destroy
    
    first_deal = Deal.find(first_deal.id)
    
    assert !first_deal.entry(3).friend_link
    
    assert !DealLink.find(:first, :conditions => "id = #{new_friend_link_id}")
    
  end
  
end