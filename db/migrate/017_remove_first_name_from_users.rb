# -*- encoding : utf-8 -*-

class RemoveFirstNameFromUsers < ActiveRecord::Migration[5.0]
  def self.up
    remove_column :users, :firstname
    remove_column :users, :lastname
  end

  def self.down
    add_column :users, :firstname, :string, :limit => 40
    add_column :users, :lastname, :string, :limit => 40
  end
end
