class FriendDeal < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
  belongs_to :friend_deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'friend_deal_id'

  def after_save
    if !FriendDeal.find(:first, :conditions => ["deal_id = ? and friend_deal_id = ?", self.friend_deal_id, self.deal_id])
      FriendDeal.create(:user_id => friend_deal.user_id, :deal_id => self.friend_deal_id, :friend_deal_id => self.deal_id )    
    end
  end
  
  def before_destroy
    FriendDeal.delete_all(["deal_id = ? and friend_deal_id = ?", self.friend_deal_id, self.deal_id])
  end
             
end
