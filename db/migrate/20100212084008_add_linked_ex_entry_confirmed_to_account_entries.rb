class AddLinkedExEntryConfirmedToAccountEntries < ActiveRecord::Migration
  def self.up
    add_column :account_entries, :linked_ex_entry_confirmed, :boolean, :null => false, :default => false

    execute "update account_entries inner join deals on account_entries.linked_ex_deal_id = deals.id set linked_ex_entry_confirmed = deals.confirmed"
  end

  def self.down
    remove_column :account_entries, :linked_ex_entry_confirmed
  end
end
