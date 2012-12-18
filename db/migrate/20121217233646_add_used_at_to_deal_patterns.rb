class AddUsedAtToDealPatterns < ActiveRecord::Migration
  def up
    add_column :deal_patterns, :used_at, :datetime
    execute "update deal_patterns set used_at = updated_at"
  end
  def down
    remove_column :deal_patterns, :used_at
  end
end
