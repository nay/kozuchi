# -*- encoding : utf-8 -*-

class CreateSingleLogins < ActiveRecord::Migration
  def self.up
    create_table :single_logins do |t|
      t.string :login
      t.string :crypted_password
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :single_logins
  end
end
