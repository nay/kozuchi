# -*- encoding : utf-8 -*-

class DropAdminUsers < ActiveRecord::Migration[5.0]
  def self.up
    drop_table :admin_users
  end

  def self.down
    create_table :admin_users do |t|
      t.column :name, :string
      t.column :hashed_password, :string, :limit => 40
    end
  end
end
