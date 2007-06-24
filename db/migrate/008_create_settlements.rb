class CreateSettlements < ActiveRecord::Migration
  def self.up
    create_table :settlements do |t|
      t.column :user_id, :integer
      t.column :account_id, :integer
      t.column :name, :text
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
      t.column :description, :text
    end
    add_column :account_entries, :settlement_id, :integer
    add_column :account_entries, :result_settlement_id, :integer
  end

  def self.down
    remove_column :account_entries, :settlement_id
    remove_column :account_entries, :result_settlement_id
    drop_table :settlements
  end
end
