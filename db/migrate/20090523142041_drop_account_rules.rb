# -*- encoding : utf-8 -*-

class DropAccountRules < ActiveRecord::Migration
  def self.up
    drop_table :account_rules
  end

  def self.down
    create_table "account_rules", :force => true do |t|
      t.integer "user_id",               :limit => 11,                :null => false
      t.integer "account_id",            :limit => 11,                :null => false
      t.integer "associated_account_id", :limit => 11,                :null => false
      t.integer "closing_day",           :limit => 11, :default => 0, :null => false
      t.integer "payment_term_months",   :limit => 11, :default => 1, :null => false
      t.integer "payment_day",           :limit => 11, :default => 0, :null => false
    end
  end
end
