# -*- encoding : utf-8 -*-

class CreateAdminUsers < ActiveRecord::Migration

  def self.up
    create_table :admin_users do |t|
      t.column :name, :string
      t.column :hashed_password, :string, :limit => 40
    end
  end

  def self.down
    drop_table :admin_users
  end
end
