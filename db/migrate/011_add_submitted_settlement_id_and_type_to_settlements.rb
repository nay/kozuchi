# -*- encoding : utf-8 -*-

class AddSubmittedSettlementIdAndTypeToSettlements < ActiveRecord::Migration[5.0]
  def self.up
    add_column :settlements, :submitted_settlement_id, :integer
    add_column :settlements, :type, :string, :limit => 40
  end

  def self.down
    remove_column :settlements, :submitted_settlement_id
    remove_column :settlements, :type
  end
end
