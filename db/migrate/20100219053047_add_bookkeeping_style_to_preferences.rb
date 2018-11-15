# -*- encoding : utf-8 -*-

class AddBookkeepingStyleToPreferences < ActiveRecord::Migration[5.0]
  def self.up
    add_column :preferences, :bookkeeping_style, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :preferences, :bookkeeping_style
  end
end
