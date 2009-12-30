# 素直につくったときにnew objectのデフォルト値が0になってしまい都合がわるいのでやめる
class RemoveNullFalseOfAmountFromAccountEntries < ActiveRecord::Migration
  def self.up
    change_column :account_entries, :amount, :integer, :null => true
    change_column_default :account_entries, :amount, nil
  end

  def self.down
    change_column_default :account_entries, :amount, 0
    change_column :account_entries, :amount, :integer, :null => false
  end
end
