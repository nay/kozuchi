class AddMobileIdentityToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :mobile_identity, :string, :limit => 40
  end

  def self.down
    remove_column :users, :mobile_identity
  end
end
