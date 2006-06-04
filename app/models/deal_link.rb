class DealLink < ActiveRecord::Base
  has_many :account_entries,
           :foreign_key => 'friend_link_id'  
  
  def another(entry_id)
    for entry in account_entries
      return entry if entry.id != entry_id.to_i
    end
    return nil
  end
  
  # Call Back Methods
  def before_destroy
    p "before_destroy DateLink #{self.id}"
    for entry in account_entries
      # 所属取引が確定済なら、リンクを外すが取引は削除しない
      if entry.deal.confirmed
        entry.friend_link_id = nil
        entry.save!
        p "before_destroy DateLink #{self.id} : Removed friend_link of account_entry #{entry.id}"
      else
        p "before_destroy DateLink #{self.id} : Going to delete Deal #{entry.deal.id}"
        entry.deal.destroy
      end
    end
  end
end
