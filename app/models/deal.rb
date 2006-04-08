class Deal < ActiveRecord::Base
  has_many :account_entry
  
  def add_entry(account_id, amount)
    @account_entries ||= []
    @account_entries << AccountEntry.new(:account_id => account_id, :amount => amount)
  end
  
  def save_deeply
    save
    @account_entries.each do |e|
      e.deal_id = self.id
      e.save
    end
  end
end
