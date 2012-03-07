# -*- encoding : utf-8 -*-

class UpdateAmountOfBalances < ActiveRecord::Migration
  
  def self.up
    for account_id, date, daily_seq, real_balance, entry_id in execute("select account_entries.account_id, deals.date, deals.daily_seq, account_entries.balance, account_entries.id from deals inner join account_entries on account_entries.deal_id = deals.id where type = 'Balance' order by date, daily_seq;")
      # 本来あるべき残高を計算
      balance = nil
      execute(
        ActiveRecord::Base.sanitize_sql_array(
          ["select sum(amount) from account_entries inner join deals on account_entries.deal_id = deals.id where account_entries.account_id = ? and (deals.date < ? or (deals.date = ? and deals.daily_seq < ?)) and deals.confirmed = ?;",
            account_id, 
            date,
            date,
            daily_seq,
            true
          ]
        )
      ).each{|result| balance = result[0].to_i}
#      p "real_balance = #{real_balance}, balance = #{balance}"
      amount = real_balance.to_i - balance # 差分
      execute("update account_entries set amount = #{amount} where id = #{entry_id};")
    end
  end

  def self.down
    for entry_id in execute("select account_entries.id from deals inner join account_entries on account_entries.deal_id = deals.id where type = 'Balance';")
      execute("update account_entries set amount = 0 where id = #{entry_id};")
    end
  end
end
