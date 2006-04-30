class AccountSummary
  attr_accessor :account, :sum
  
  def initialize(account, sum)
    @account = account
    @sum = sum
  end
  
  def name
    @account.account_type == 1 ? "不明金(#{@account.name})" : @account.name  
  end
  
  def self.get_sum(summaries)
    sum = 0
    summaries.each do |s|
      sum += (s.sum || 0)
    end
    return sum
  end
end