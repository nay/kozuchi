class RemoveAccountTypeCodeFromAccounts < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :account_type_code
    remove_column :accounts, :asset_type_code
    add_column :accounts, :asset_kind, :string
    # typeをみてasset_kindに投入する
    execute "update accounts set asset_kind = 'banking_facility' where type = 'BankingFacility' or type = 'Account::BankingFacility'"
    execute "update accounts set asset_kind = 'cache' where type = 'Cache' or type = 'Account::Cache'"
    execute "update accounts set asset_kind = 'capital_fund' where type = 'CapitalFund' or type = 'Account::CapitalFund'"
    execute "update accounts set asset_kind = 'credit' where type = 'Credit' or type = 'Account::Credit'"
    execute "update accounts set asset_kind = 'credit_card' where type = 'CreditCard' or type = 'Account::CreditCard'"
  end

  def self.down
    add_column :accounts, :account_type_code, :integer,  :limit => 11
    add_column :accounts, :asset_type_code, :integer,  :limit => 11
    remove_column :accounts, :asset_kind
  end
end
