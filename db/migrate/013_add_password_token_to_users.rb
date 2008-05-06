class AddPasswordTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :password_token, :string, :limit => 40
    add_column :users, :password_token_expires_at, :datetime    
  end

  def self.down
    remove_column :users, :password_token
    remove_column :users, :password_token_expires_at
  end
end
