class RemoveSaltedPasswordFromUsers < ActiveRecord::Migration
  def self.up
    execute "update users set crypted_password = salted_password where type = 'LoginEngineUser';"
    remove_column :users, :salted_password
  end

  def self.down
    add_column :users, :salted_password, :string, :limit => 40, :default => "", :null => false
    execute "update users set salted_password = crypted_password where type = 'LoginEngineUser';"
  end
end
