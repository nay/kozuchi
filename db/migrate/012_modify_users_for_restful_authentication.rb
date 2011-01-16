class ModifyUsersForRestfulAuthentication < ActiveRecord::Migration

  def self.up
    add_column :users, :crypted_password,  :string, :limit => 40
    add_column :users, :remember_token,    :string
    add_column :users, :remember_token_expires_at, :datetime
    add_column :users, :activated_at, :datetime
    add_column :users, :type, :string, :limit => 40

    rename_column :users, :security_token, :activation_code

    execute "update users set type = 'LoginEngineUser';"
    
    remove_column :users, :token_expiry
    remove_column :users, :deleted
    remove_column :users, :delete_after

    User.update_all(["activated_at = ?, activation_code = NULL", Time.now.utc], "verified = 1")
    
    remove_column :users, :verified
    

#    Restful Authentication requires following schema.
#    create_table "users", :force => true do |t|
#      t.column :login,                     :string
#      t.column :email,                     :string
#      t.column :crypted_password,          :string, :limit => 40
#      t.column :salt,                      :string, :limit => 40
#      t.column :created_at,                :datetime
#      t.column :updated_at,                :datetime
#      t.column :remember_token,            :string
#      t.column :remember_token_expires_at, :datetime
#      t.column :activation_code, :string, :limit => 40
#      t.column :activated_at, :datetime    
#    end
#
#  The Original Schema is as followings.
#
#  create_table "users", :force => true do |t|
#    t.string   "login",           :limit => 80, :default => "", :null => false
#    t.string   "salted_password", :limit => 40, :default => "", :null => false
#    t.string   "email",           :limit => 60, :default => "", :null => false
#    t.string   "firstname",       :limit => 40
#    t.string   "lastname",        :limit => 40
#    t.string   "salt",            :limit => 40, :default => "", :null => false
#    t.integer  "verified",                      :default => 0
#    t.string   "role",            :limit => 40
#    t.string   "security_token",  :limit => 40
#    t.datetime "token_expiry"
#    t.datetime "created_at"
#    t.datetime "updated_at"
#    t.datetime "logged_in_at"
#    t.integer  "deleted",                       :default => 0
#    t.datetime "delete_after"
#  end

  end

  def self.down
    execute "delete from users where type is NULL or type != 'LoginEngineUser';"
    add_column    :users, :deleted, :integer, :default => 0
    add_column    :users, :delete_after, :datetime
    add_column    :users, :verified, :integer, :default => 0
    add_column    :users, :token_expiry, :datetime
    execute "update users set verified = 1 where activated_at is not null;"

    rename_column :users, :activation_code, :security_token

    remove_column :users, :crypted_password
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
    remove_column :users, :activated_at
    remove_column :users, :type
  end
end
