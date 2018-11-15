# -*- encoding : utf-8 -*-

class AddBusinessUseToPreferences < ActiveRecord::Migration[5.0]
  def self.up
    add_column(:preferences, :business_use, :boolean, :default => false, :null => false)
  end

  def self.down
    remove_column(:preferences, :business_use)
  end
end
