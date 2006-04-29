require 'time'

class Deal < ActiveRecord::Base
  has_many :account_entries
  attr_writer :minus_account_id, :plus_account_id, :amount
  
  def minus_account_id
    return @minus_account_id if @minus_account_id
    for entry in self.account_entries
      if entry.amount < 0
        @minus_account_id = entry.account_id
        return @minus_account_id
      end
    end
    return nil
  end

  def plus_account_id
    return @plus_account_id if @plus_account_id
    for entry in self.account_entries
      if entry.amount >= 0
        @plus_account_id = entry.account_id
        return @plus_account_id
      end
    end
    return nil
  end

  def amount
    return @amount if @amount
    for entry in self.account_entries
      if entry.amount
        @amount = entry.amount.abs
        return @amount
      end
    end
    return nil
  end
  
  def self.create_or_update_simple(deal, user_id, date, insert_before)
    deal.user_id = user_id
    deal.date = date
    # add minus
    deal.add_entry(deal.minus_account_id.to_i, deal.amount.to_i*(-1))
    deal.add_entry(deal.plus_account_id.to_i, deal.amount.to_i)
    deal.save_deeply(insert_before)
    deal
  end
  
  def self.create_balance(user_id, date, insert_before, account_id, amount)
    deal = Deal.new
    deal.user_id = user_id
    deal.date = date
    deal.summary = "残高確認" #todo
    deal.add_balance_entry(account_id, amount)
    deal.save_deeply(insert_before)
    deal
  end
  
  def self.get_for_month(user_id, year, month)
    start_inclusive = Date.new(year, month, 1)
    end_exclusive = start_inclusive >> 1
    Deal.find(:all, :conditions => ["user_id = ? and date >= ? and date < ?", user_id, start_inclusive, end_exclusive], :order => "date, daily_seq")
  end

  def self.get_for_account(user_id, account_id, year, month)
    start_inclusive = Date.new(year, month, 1)
    end_exclusive = start_inclusive >> 1
    #Deal.find(:all,
    #          :conditions => ["et.user_id = ? and et.account_id = ? and date >= ? and date < ?", user_id, account_id, start_inclusive, end_exclusive],
    #          :joins => "as dl inner join account_entries as et on dl.id = et.deal_id",
    #          :order => "date, daily_seq")
    # TODO: 複数テーブルの検索がなぜかうまくいかないのでメモリ上で処理する
    deals = self.get_for_month(user_id, year, month)
    p "deals size in get_for_account " + deals.size.to_s
    result = Array.new
    for deal in deals do
      for account_entry in deal.account_entries do
        p "account_entry.account_id = " + account_entry.account_id.to_s
        p "account_id = " + account_id.to_s
        if account_entry.account_id.to_i == account_id.to_i
          p "added result"
          result << deal
          break
        else
          p "didn't added result"
        end
      end
    end
    p "result size = " + result.size.to_s
    return result 
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
  
  def add_balance_entry(account_id, amount)
    self.account_entries << AccountEntry.new(:user_id => self.user_id, :account_id => account_id, :amount => 0, :balance => amount)
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
