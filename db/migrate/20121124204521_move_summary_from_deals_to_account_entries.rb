class MoveSummaryFromDealsToAccountEntries < ActiveRecord::Migration[5.0]
  def up
    add_column :account_entries, :summary, :string, :limit => 64, :default => "", :null => false
    for deal_id, summary in execute "SELECT id, summary FROM deals;"
      execute "UPDATE account_entries SET summary = '#{quote_string(summary)}' WHERE deal_id = #{deal_id};"
    end
    rename_column :deals, :summary, :old_summary # for back up, will be deleted later.
  end

  def down
    rename_column :deals, :old_summary, :summary
    remove_column :account_entries, :summary
  end
end
