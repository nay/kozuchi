class AddUsedAtToDealPatterns < ActiveRecord::Migration[5.0]
  def up
    add_column :deal_patterns, :used_at, :datetime
    execute "update deal_patterns set used_at = updated_at"
  end
  def down
    remove_column :deal_patterns, :used_at
  end
end
