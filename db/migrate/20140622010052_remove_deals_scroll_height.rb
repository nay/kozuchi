class RemoveDealsScrollHeight < ActiveRecord::Migration
  def up
    remove_column :preferences, :deals_scroll_height
  end

  def down
    add_column :preferences, :deals_scroll_height, :string, limit: 20
  end
end
