require 'time'

class BaseDeal < ActiveRecord::Base
  set_table_name "deals"
  has_many :account_entries,
           :foreign_key => 'deal_id',
           :exclusively_dependent => true,
           :order => "amount"

  def balance
    return nil
  end
  
  def self.get(deal_id, user_id)
    return BaseDeal.find(:first, :conditions => ["id = ? and user_id = ?", deal_id, user_id])
  end

  def self.get_for_month(user_id, year, month)
    start_inclusive = Date.new(year, month, 1)
    end_exclusive = start_inclusive >> 1
    BaseDeal.find(:all, :conditions => ["user_id = ? and date >= ? and date < ?", user_id, start_inclusive, end_exclusive], :order => "date, daily_seq")
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


  def set_daily_seq(insert_before = nil)
    # 挿入の場合
    if insert_before
      # 日付が違ったら例外
      raise ArgumentError, "An inserting point should be in the same date with the target." if insert_before.date != self.date 

      Deal.connection.update(
        "update deals set daily_seq = daily_seq +1 where user_id == #{self.user_id} and date == '#{self.date.strftime('%Y-%m-%d')}' and ( daily_seq > #{insert_before.daily_seq}  or (daily_seq == #{insert_before.daily_seq} and id >= #{insert_before.id}));"
#        "update deals set daily_seq = daily_seq +1 where user_id == #{self.user_id} and ( daily_seq > #{insert_before.daily_seq}  or (daily_seq == #{insert_before.daily_seq} and id >= #{insert_before.id}));"
      )
      self.daily_seq = insert_before.daily_seq;
    
    # 追加の場合
    else
      max = Deal.connection.select_one(
        "select max(daily_seq) from deals where user_id == #{self.user_id} and date == '#{self.date.strftime('%Y-%m-%d')}';"
#        "select max(daily_seq) from deals where user_id == #{self.user_id} ;"
      ).values[0] || "0"
      p "max=#{max}"
      self.daily_seq = 1 + max.to_i
    end
    
  end
  
end