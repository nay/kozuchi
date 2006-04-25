class Balance
  attr_accessor :account_id, :amount
  
  def initialize(values = nil)
    return if !values
    @account_id = values["account_id"]
    @amount = values["amount"]
  end

  def account_id_i
    @account_id.to_i
  end
  
  def amount_i
    @amount.to_i
  end

end