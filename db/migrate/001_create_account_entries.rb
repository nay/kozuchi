class CreateAccountEntries < ActiveRecord::Migration
  def self.up
    create_table :account_entries do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :account_entries
  end
end
