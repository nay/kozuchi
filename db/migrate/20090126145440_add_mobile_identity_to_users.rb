# -*- encoding : utf-8 -*-

class AddMobileIdentityToUsers < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :mobile_identity, :string, :limit => 40
  end

  def self.down
    remove_column :users, :mobile_identity
  end
end
