class AddTypeToAccounts < ActiveRecord::Migration
  def self.up
#    add_column(:accounts, :type, :text)
    execute("update accounts set type = 'Income' where account_type_code = 3;")
    execute("update accounts set type = 'Expense' where account_type_code = 2;")
    execute("update accounts set type = 'Cache' where account_type_code = 1 and asset_type_code = 1;")
    execute("update accounts set type = 'BankingFacility' where account_type_code = 1 and asset_type_code = 2;")
    execute("update accounts set type = 'CreditCard' where account_type_code = 1 and asset_type_code = 3;")
    execute("update accounts set type = 'Credit' where account_type_code = 1 and asset_type_code = 4;")
    execute("update accounts set type = 'CaptitalFund' where account_type_code = 1 and asset_type_code = 5;")
  end

  def self.down
    remove_column(:accounts, :type)
  end
end
