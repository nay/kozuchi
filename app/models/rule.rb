class Rule < ActiveRecord::Base
  belongs_to :associated_account,
             :class_name => 'Account',
             :foreign_key => 'associated_account_id'
  has_many   :accounts
  
  def self.find_all(user_id)
    return find(:all, :conditions => ['user_id = ?', user_id])
  end
  
  def self.get(user_id, id)
    return find(:first, :conditions => ["user_id = ? and id = ?", user_id, id])
  end
end
