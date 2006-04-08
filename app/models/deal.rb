require 'time'

class Deal < ActiveRecord::Base
  has_many :account_entries
  
  def self.create_simple(date, summary, amount, minus_account_id, plus_account_id)
    deal = Deal.new
    deal.date = date
    deal.summary = summary
    # add minus
    deal.add_entry(minus_account_id, amount*(-1))
    deal.add_entry(plus_account_id, amount)
    deal.save_deeply
    deal
  end
  
  def self.get_for_month(year, month)
    start_inclusive = Date.new(year, month, 1)
    end_exclusive = start_inclusive >> 1
    p start_inclusive
    p end_exclusive
    Deal.find(:all, :conditions => ["date >= ? and date < ?", start_inclusive, end_exclusive], :order => "date desc, id desc")
  end

  def destroy_deeply
    self.account_entries.each do |e|
      e.destroy
    end
    destroy
  end
  
  def add_entry(account_id, amount)
    self.account_entries << AccountEntry.new(:account_id => account_id, :amount => amount)
  end
  
  def save_deeply
    save
    self.account_entries.each do |e|
      e.deal_id = self.id
      e.save
    end
  end
end
