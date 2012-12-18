# -*- encoding : utf-8 -*-
class CreateEntryPatterns < ActiveRecord::Migration
  def up
    create_table :entry_patterns do |t|
      t.integer :user_id, :null => false
      t.integer :deal_pattern_id, :null => false
      t.boolean :creditor, :null => false, :default => false
      t.integer :line_number, :null => false, :defualt => 0
      t.string :summary, :null => false, :default => ''
      t.integer :account_id
      t.integer :amount
    end
    add_index :entry_patterns, [:deal_pattern_id, :creditor, :line_number],
      :name => :creditor_line_number,
      :unique => true
  end

  def down
    remove_index :entry_patterns, :name => :creditor_line_number
    drop_table :entry_patterns
  end
end
