class CreateDealLinks < ActiveRecord::Migration
  def self.up
    create_table :deal_links do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :deal_links
  end
end
