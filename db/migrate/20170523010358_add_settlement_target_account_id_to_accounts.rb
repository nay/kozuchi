class AddSettlementTargetAccountIdToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :settlement_target_account_id, :integer
    add_column :accounts, :settlement_term_margin, :integer, default: 7, null: false
  end
end
