class AddSettlementPaidOnToAccounts < ActiveRecord::Migration[5.0]
  def change
    # 前月末で締めたものを当月末に支払うのをデフォルトにする
    add_column :accounts, :settlement_paid_on, :integer, null: false, default: 31
    add_column :accounts, :settlement_closed_on_month, :integer, null: false, default: 1  # 前月
    add_column :accounts, :settlement_closed_on_day,   :integer, null: false, default: 31 # 31日
  end
end
