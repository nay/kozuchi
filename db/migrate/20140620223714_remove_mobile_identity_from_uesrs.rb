class RemoveMobileIdentityFromUesrs < ActiveRecord::Migration[5.0]
  def up
    remove_column :users, :mobile_identity
  end

  def down
    add_column :users, :mobile_identity, :string, :limit => 40
  end
end
