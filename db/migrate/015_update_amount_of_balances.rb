class UpdateAmountOfBalances < ActiveRecord::Migration

  # モデルクラスの定義
  class BaseDeal < ActiveRecord::Base
    set_table_name "deals"
  end
  class Balance < BaseDeal
    has_one :entry, :class_name => "AccountEntry", :foreign_key => "deal_id"
  end
  class AccountEntry < ActiveRecord::Base
  end
  
  def self.up
    Balance.transaction do
      # 残高記入を順に取り出し、新方式でamountをセットしていく
      balances = Balance.find(:all, :order => "date, daily_seq")
      for b in balances
        balance = AccountEntry.sum(:amount,
          :joins => "inner join deals on account_entries.deal_id = deals.id",
          :conditions => ["account_entries.account_id = ? && (deals.date < ? or (deals.date = ? && deals.daily_seq > ?))", b.entry.account_id, b.date, b.date, b.daily_seq]
        ) || 0
        amount = b.entry.balance - balance
        b.entry.update_attribute(:amount, amount)
      end
    end
  end

  def self.down
    Balance.transaction do
      balances = Balance.find(:all, :order => "date, daily_seq")
      for b in balances
        b.entry.update_attribute(:amount, 0)
      end
    end
  end
end
