#require 'asset'
class Account::BankingFacility < Account::Asset
  type_order 2
  asset_name '金融機関口座'
  rule_associatable true
  
  def self.types
    []
  end

end
