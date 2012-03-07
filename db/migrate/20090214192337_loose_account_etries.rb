# -*- encoding : utf-8 -*-

class LooseAccountEtries < ActiveRecord::Migration
  def self.up
    change_column :account_entries, :user_id, :integer, :null => true
    change_column :account_entries, :account_id, :integer, :null => true
    change_column :account_entries, :deal_id, :integer, :null => true
  end

  def self.down
    change_column :account_entries, :user_id, :integer, :null => false
    change_column :account_entries, :account_id, :integer, :null => false
    change_column :account_entries, :deal_id, :integer, :null => false
  end
end
