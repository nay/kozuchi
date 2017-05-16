class AddConfirmToAccountEntries < ActiveRecord::Migration[5.0]
  def up
    add_column :account_entries, :confirmed, :boolean, default: true, null: false
    execute "UPDATE account_entries INNER JOIN deals ON deals.id = account_entries.deal_id SET account_entries.confirmed = deals.confirmed"
    add_index  :account_entries, [:date, :daily_seq]
    add_index  :account_entries, :confirmed
    add_index  :account_entries, :initial_balance
  end
  def down
    remove_index  :account_entries, :initial_balance
    remove_index  :account_entries, [:date, :daily_seq]
    remove_index  :account_entries, :confirmed
    remove_column :account_entries, :confirmed
  end
end
