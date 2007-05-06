#require 'asset'
class Account::CreditCard < Account::Asset
  type_order 3
  asset_name 'クレジットカード'
  rule_applicable true
end
