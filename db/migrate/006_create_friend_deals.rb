class CreateFriendDeals < ActiveRecord::Migration
  def self.up
    create_table :friend_deals do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :friend_deals
  end
end
