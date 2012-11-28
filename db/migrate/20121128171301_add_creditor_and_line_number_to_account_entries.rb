class AddCreditorAndLineNumberToAccountEntries < ActiveRecord::Migration
  def up
    add_column :account_entries, :creditor, :boolean, :null => false, :default => 0
    add_column :account_entries, :line_number, :integer, :null => false, :default => 0

    prev_deal_id = nil
    for entry_id, deal_id, amount in execute "SELECT id, deal_id, amount FROM account_entries WHERE type = 'Entry::General' ORDER BY deal_id, id"
      if prev_deal_id != deal_id
        debtor_line_number = -1
        creditor_line_number = -1
      end
      execute "UPDATE account_entries SET creditor = #{amount >= 0 ? 0 : 1}, line_number = #{amount >= 0 ? debtor_line_number += 1 : creditor_line_number += 1} WHERE id = #{entry_id}"
      prev_deal_id = deal_id
    end

    add_index :account_entries, [:deal_id, :creditor, :line_number], :unique => true
  end

  def down
    remove_index :account_entries, [:deal_id, :creditor, :line_number]
    remove_column :account_entries, :line_number
    remove_column :account_entries, :creditor
  end
end
