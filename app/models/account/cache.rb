#require 'asset'
class Account::Cache < Account::Asset
  type_order 1
  asset_name '現金'

  def validate
    p "validate cache"
  end

end
