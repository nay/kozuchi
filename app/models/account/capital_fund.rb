#require 'asset'
class Account::CapitalFund < Account::Asset
  type_order 5
  asset_name '資本金'
  business_only true
  def self.types
    []
  end

end
