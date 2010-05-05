class AddUsesComplexDealToPreferences < ActiveRecord::Migration
  def self.up
    add_column :preferences, :uses_complex_deal, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :preferences, :uses_complex_deal
  end
end
