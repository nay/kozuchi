# -*- encoding : utf-8 -*-

class CreateFriendPermissions < ActiveRecord::Migration[5.0]
  def self.up
    create_table :friend_permissions do |t|
      t.integer :user_id
      t.integer :target_id
      t.string :type

      t.timestamps
    end
    # Move Exsiting Data
    for user_id, friend_user_id, level in execute("select user_id, friend_user_id, friend_level from friends") do
      if level.to_i < 0
        type = "Rejection"
      elsif level.to_i > 0
        type = "Acceptance"
      else
        next
      end
      execute("insert into friend_permissions (user_id, target_id, type, created_at, updated_at) values (#{user_id}, #{friend_user_id}, '#{type}', now(), now())")
    end

  end

  def self.down
    drop_table :friend_permissions
  end
end
