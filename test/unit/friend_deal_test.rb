require File.dirname(__FILE__) + '/../test_helper'

class FriendDealTest < ActiveSupport::TestCase
  
  def setup
    @user1 = users(:old)
    @user2 = users(:old2)
  end
  
  # 前提条件のテスト
  def test_conditions
    # old と old2はlevel1のフレンドである
    assert @user1.friend?(@user2)
    assert @user2.friend?(@user1)
  end

  # TODO:とおらない
  # フレンド取引のテスト
#  def test_not_confirmed
#    # 作成
#    first_deal = Deal::General.new(
#      :summary => 'second へ貸した',
#      :amount => 1000,
#      :minus_account_id => accounts(:first_cache).id,
#      :plus_account_id => accounts(:first_second).id,
#      :user_id => users(:old).id,
#      :date => Date.parse("2006/05/01")
#    )
#    first_deal.save!
#    first_deal.reload
#
#    first_second_entry = first_deal.entry(accounts(:first_second).id)
#    assert first_second_entry.linked_ex_entry_id
##    ex_entry_id = first_second_entry.linked_ex_entry_id # あとでつかう
#    another_entry = Entry::Base.find(first_second_entry.linked_ex_entry_id)
#    assert_equal false, another_entry.deal.confirmed
#
#    assert_equal users(:old2).id, first_second_entry.linked_user_id
#    assert_equal accounts(:second_first).id, another_entry.account_id
#    assert 1000*(-1), another_entry.amount
#
#    # 相手が未確定な状態で金額を変更したら相手も変わる
#    first_deal.attributes = {:amount => 1200}
#    first_deal.save!
#
#    # とりなおす
#    another_entry = Entry::Base.find(first_second_entry.linked_ex_entry_id)
#    assert another_entry
#
#    another_entry = Entry::Base.find(another_entry.id)
#    assert_equal 1200*(-1), another_entry.amount
#
#    # 相手が未確定な状態で削除したら相手は消える
#    first_deal.destroy
#    another_entry = Entry::Base.find(:first, :conditions => "id = #{another_entry.id}")
#    assert !another_entry
#  end
  
#  def test_confirmed
#    # 作成
#    first_deal = Deal::General.new(
#      :summary => 'second に借りた',
#      :amount => 1000,
#      :minus_account_id => accounts(:first_second).id,
#      :plus_account_id => accounts(:first_cache).id,
#      :user_id => users(:old).id,
#      :date => Date.parse("2006/05/02")
#    )
#    first_deal.save!
#    first_deal.reload
#
#    first_second_entry = first_deal.entry(accounts(:first_second).id)
#    assert first_second_entry.linked_ex_entry_id
#    another_entry = Entry::Base.find_by_linked_ex_entry_id(first_second_entry.id)
#    assert_equal users(:old2).id, another_entry.user_id
#    assert_equal accounts(:second_first).id, another_entry.account_id
#    assert 1000, another_entry.amount
#
#    # 相手を確定にする
#    friend_deal = another_entry.deal
#    friend_deal.confirm
#
#    friend_deal = another_entry.deal(true) # とりなおす
#
#    assert friend_deal.confirmed
#
#    assert friend_deal.entry(accounts(:second_first).id).linked_ex_deal_id
#
#    # 変更したら、新しい相手ができる。旧相手はリンクがきれる。
#    first_deal.attributes = {:amount => 1200}
#    first_deal.save!
#
#    friend_deal = Deal::General.find(friend_deal.id)
#    assert !friend_deal.entry(accounts(:second_first).id).linked_ex_deal_id # リンクがきれたはず。
#
#    assert !DealLink.find(:first, :conditions => "id = #{friend_link_id}")
#
#    # 新しい相手ができたはず。
#    first_second_entry = first_deal.entry(accounts(:first_second).id)
#    new_friend_link = first_second_entry.friend_link
#
#    assert new_friend_link.id != friend_link_id
#    new_friend_link_id = new_friend_link.id
#
#    new_another_entry = new_friend_link.another(first_second_entry.id)
#
#    assert new_another_entry
#    assert_equal 1200, new_another_entry.amount
#
#    # 新しい相手を確定にする
#    new_friend_deal = new_another_entry.deal
#    new_friend_deal.confirmed = true
#    new_friend_deal.save!
#
#    # 新しい相手を削除すると自分のリンクはきえるが自分は残る
#    new_friend_deal.destroy
#
#    first_deal = Deal::General.find(first_deal.id)
#
#    assert !first_deal.entry(accounts(:first_second).id).linked_ex_deal_id
#
#    assert !DealLink.find(:first, :conditions => "id = #{new_friend_link_id}")
#
#  end
  
end