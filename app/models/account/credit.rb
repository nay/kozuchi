#require 'asset'
class Account::Credit < Account::Asset
  type_order 4
  asset_name '債権'
  rule_applicable true
end
