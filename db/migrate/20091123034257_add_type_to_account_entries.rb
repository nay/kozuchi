class AddTypeToAccountEntries < ActiveRecord::Migration
  def self.up
    add_column :account_entries, :type, :string
    execute "update account_entries inner join deals on deals.id = account_entries.deal_id set account_entries.type = deals.type;"
  end

  def self.down
    remove_column :account_entries, :type
  end
end
