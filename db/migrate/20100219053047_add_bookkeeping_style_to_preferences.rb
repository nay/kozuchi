class AddBookkeepingStyleToPreferences < ActiveRecord::Migration
  def self.up
    add_column :preferences, :bookkeeping_style, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :preferences, :bookkeeping_style
  end
end
