class CreateDeals < ActiveRecord::Migration
  def self.up
    create_table :deals do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :deals
  end
end
