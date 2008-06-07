class AddInitialBalanceToAccountEntries < ActiveRecord::Migration
  class AccountEntry < ActiveRecord::Base
  end
  def self.up
    add_column :account_entries, :initial_balance, :boolean, :null => false, :default => false
    AddInitialBalanceToAccountEntries::AccountEntry.transaction do
      AddInitialBalanceToAccountEntries::AccountEntry.find(:all, :select => 'distinct account_id').each do |e|
        initial_balance_entry = AddInitialBalanceToAccountEntries::AccountEntry.find(:first, 
          :joins => "inner join deals on deals.id = account_entries.deal_id",
          :conditions => "account_entries.account_id = #{e.account_id}", :order => "deals.date, deals.daily_seq")
        # 現在ひとつもないなら特に仕事なし
        next unless initial_balance_entry
        AddInitialBalanceToAccountEntries::AccountEntry.update_all(["initial_balance = ?", true], "id = #{initial_balance_entry.id}")
      end
    end
  end

  def self.down
    remove_column :account_entries, :initial_balance
  end
end
