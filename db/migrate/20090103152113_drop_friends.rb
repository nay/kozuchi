# -*- encoding : utf-8 -*-

class DropFriends < ActiveRecord::Migration[5.0]
  def self.up
    drop_table :friends
  end

  def self.down
    create_table "friends", :force => true do |t|
      t.integer "user_id",        :limit => 11,                :null => false
      t.integer "friend_user_id", :limit => 11,                :null => false
      t.integer "friend_level",   :limit => 11, :default => 1, :null => false
    end
    # Move Exsiting Data
    for user_id, target_id, type in execute("select user_id, target_id, type from friend_permissions") do
      if type == 'Acceptance'
        level = 1
      elsif type == "Rejection"
        level = -1
      else
        next
      end
      execute("insert into friends (user_id, friend_user_id, friend_level) values (#{user_id}, #{target_id}, #{level})")
    end
  end
end
