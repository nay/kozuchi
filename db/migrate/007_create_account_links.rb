class CreateAccountLinks < ActiveRecord::Migration
  def self.up
    create_table :account_links do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :account_links
  end
end
