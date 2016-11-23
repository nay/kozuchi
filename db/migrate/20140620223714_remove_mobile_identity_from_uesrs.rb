class RemoveMobileIdentityFromUesrs < ActiveRecord::Migration
  def up
    remove_column :users, :mobile_identity
  end

  def down
    add_column :users, :mobile_identity, :string, :limit => 40
  end
end
