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
    add_column :account_entries, :settlement_result, :boolean
  end

  def self.down
    remove_column :account_entries, :settlement_id
    remove_column :account_entries, :settlement_result
    drop_table :settlements
  end
end
