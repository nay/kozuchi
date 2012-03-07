# -*- encoding : utf-8 -*-

class ChangeAccountType < ActiveRecord::Migration
  def self.up
    rename_column(:accounts, :account_type, :account_type_code)
    rename_column(:accounts, :asset_type, :asset_type_code)
  end

  def self.down
    rename_column(:accounts, :account_type_code, :account_type)
    rename_column(:accounts, :asset_type_code, :asset_type)
  end
end
