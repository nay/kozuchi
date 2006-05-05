class AccountRule < ActiveRecord::Base
  belongs_to :associated_account,
             :class_name => 'Account',
             :foreign_key => 'associated_account_id'
  belongs_to :account
  
  def self.find_all(user_id)
    return find(:all, :conditions => ['user_id = ?', user_id])
  end
  
  def self.get(user_id, id)
    return find(:first, :conditions => ["user_id = ? and id = ?", user_id, id])
  end
  
  def self.find_associated_with(associated_account_id)
    return find(:all, :conditions => ["associated_account_id = ?", associated_account_id])
  end
  
  def self.find_binded_with(binded_account_id)
    return find(:all, :conditions => ["account_id = ?", binded_account_id])
  end
  
end
