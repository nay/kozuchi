class DealLink < ActiveRecord::Base
  has_many :account_entries,
           :foreign_key => 'friend_link_id'  
  
  def another(entry_id)
    for entry in account_entries
      return entry if entry.id.to_i != entry_id.to_i
      p "another #{self.id}: entry #{entry.id} was not selected."
    end
    p "no another"
    return nil
  end
end
