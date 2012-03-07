# -*- encoding : utf-8 -*-

class AddCreatedAtToDeals < ActiveRecord::Migration
  def self.up
    add_column(:deals, :created_at, :timestamp)
    add_column(:deals, :updated_at, :timestamp)
  end

  def self.down
    remove_column(:deals, :created_at)
    remove_column(:deals, :updated_at)
  end
end
