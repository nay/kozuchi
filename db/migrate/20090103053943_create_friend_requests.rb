class CreateFriendRequests < ActiveRecord::Migration
  def self.up
    create_table :friend_requests do |t|
      t.integer :user_id
      t.integer :sender_id

      t.timestamps
    end
    # Create Friend Request Records from Acceptance
    for user_id, target_id in execute("select user_id, target_id from friend_permissions where type = 'Acceptance'")
      execute("insert into friend_requests (user_id, sender_id, created_at, updated_at) values (#{target_id}, #{user_id}, now(), now())")
    end
  end

  def self.down
    drop_table :friend_requests
  end
end
