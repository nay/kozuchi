# ざっくりindexをはる
class AddIndexesToAccountEntries < ActiveRecord::Migration
  def self.up
    add_index :account_entries, :account_id
    add_index :account_entries, :deal_id
    add_index :account_entries, :user_id
    add_index :account_entries, :friend_link_id
    add_index :account_entries, :settlement_id
    add_index :account_entries, :result_settlement_id

    add_index :account_links, :account_id
    add_index :account_links, :connected_account_id

    add_index :deals, :user_id
    add_index :deals, :parent_deal_id
    
    add_index :accounts, :user_id
    add_index :accounts, :partner_account_id
  end

  def self.down
    remove_index :account_entries, :account_id
    remove_index :account_entries, :deal_id
    remove_index :account_entries, :user_id
    remove_index :account_entries, :friend_link_id
    remove_index :account_entries, :settlement_id
    remove_index :account_entries, :result_settlement_id

    remove_index :account_links, :account_id
    remove_index :account_links, :connected_account_id

    remove_index :deals, :user_id
    remove_index :deals, :parent_deal_id
    
    remove_index :accounts, :user_id
    remove_index :accounts, :partner_account_id
  end
end
