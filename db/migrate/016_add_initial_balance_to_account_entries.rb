class AddInitialBalanceToAccountEntries < ActiveRecord::Migration
  def self.up
    add_column :account_entries, :initial_balance, :boolean, :null => false, :default => false
    for account_id in execute("select id from accounts;")
      initial_balance_entry_id = nil
      execute(
        "select account_entries.id from account_entries inner join deals on deals.id = account_entries.deal_id where account_entries.account_id = #{account_id} and deals.type = 'Balance' order by deals.date, deals.daily_seq limit 1"
      ).each{|r| initial_balance_entry_id = r[0]; break}
      next unless initial_balance_entry_id
      execute(
        ActiveRecord::Base.sanitize_sql_array(["update account_entries set initial_balance = ? where id = #{initial_balance_entry_id}", true])
      )
    end
  end

  def self.down
    remove_column :account_entries, :initial_balance
  end
end
