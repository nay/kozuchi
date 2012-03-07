# -*- encoding : utf-8 -*-

class AddDailyBookingToPreferences < ActiveRecord::Migration
  def self.up
    add_column(:preferences, :use_daily_booking, :boolean, :default => true, :null => false)
  end

  def self.down
    remove_column(:preferences, :use_daily_booking)
  end
end
