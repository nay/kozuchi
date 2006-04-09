require 'time'

class Deal < ActiveRecord::Base
  has_many :account_entries
  
  def self.create_simple(user_id, date, insert_before, summary, amount, minus_account_id, plus_account_id)
    deal = Deal.new
    deal.user_id = user_id
    deal.date = date
    deal.summary = summary
    # add minus
    deal.add_entry(minus_account_id, amount*(-1))
    deal.add_entry(plus_account_id, amount)
    deal.save_deeply(insert_before)
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
    self.account_entries << AccountEntry.new(:user_id => self.user_id, :account_id => account_id, :amount => amount)
  end
  
  def save_deeply(insert_before)
    self.daily_seq = get_daily_seq(insert_before)
    save
    self.account_entries.each do |e|
      e.deal_id = self.id
      e.save
    end
  end
  
  def get_daily_seq(insert_before)
    # 挿入の場合
    if insert_before
      # 日付が違ったら例外
      raise ArgumentError, "An inserting point should be in the same date with the target." if insert_before.date != self.date 

      Deal.connection.update(
        "update deals set daily_seq = daily_seq +1 where user_id == #{self.user_id} and date == '#{self.date.strftime('%Y-%m-%d')}' and ( daily_seq > #{insert_before.daily_seq}  or (daily_seq == #{insert_before.daily_seq} and id >= #{insert_before.id}));"
#        "update deals set daily_seq = daily_seq +1 where user_id == #{self.user_id} and ( daily_seq > #{insert_before.daily_seq}  or (daily_seq == #{insert_before.daily_seq} and id >= #{insert_before.id}));"
      )
      return insert_before.daily_seq;
    
    # 追加の場合
    else
      max = Deal.connection.select_one(
        "select max(daily_seq) from deals where user_id == #{self.user_id} and date == '#{self.date.strftime('%Y-%m-%d')}';"
#        "select max(daily_seq) from deals where user_id == #{self.user_id} ;"
      ).values[0] || "0"
      p "max=#{max}"
      return 1 + max.to_i
    end
    
  end
end
