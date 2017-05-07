class AddActiveInAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :active, :boolean, default: true, null: false
    add_column :accounts, :description, :text
    add_column :accounts, :settlement_order_asc, :boolean, default: true, null: false
  end
end
