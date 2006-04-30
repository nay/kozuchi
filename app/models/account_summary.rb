class AccountSummary
  attr_accessor :account, :sum
  
  def initialize(account, sum)
    @account = account
    @sum = sum
  end
end