class CreateRules < ActiveRecord::Migration
  def self.up
    create_table :rules do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :rules
  end
end
