class Flow::Base
  attr_reader :account, :list
  def initialize(account, list)
    @list = list
    @account = account
  end
  def percentage
    return nil if flow < 0
    plus_sum = list.plus_sum
    return 0 if plus_sum == 0
    (flow * 100.0 / list.plus_sum).round
  end
  def unknown?
    account.respond_to? :unknown
  end

  def name
    unknown? ? "不明金(#{account.name})" : account.name
  end

end