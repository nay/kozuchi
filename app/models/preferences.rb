class Preferences < ActiveRecord::Base
  set_table_name "preferences"
  belongs_to :user
  
  validates_uniqueness_of :user_id
  
  def self.get(user_id)
    return find(:first, :conditions => ["user_id = ?", user_id]) || Preferences.new(:user_id => user_id)
  end
  
  
end