class Flow::Base
  attr_reader :list
  def initialize(account_name, flow, unknown, list, previous_flow)
    @list = list
    @account_name = account_name
    @flow = flow
    @previous_flow = previous_flow
    @unknown = unknown
  end
  def percentage
    return nil if flow < 0
    plus_sum = list.plus_sum
    return 0 if plus_sum == 0
    (flow * 100.0 / list.plus_sum).round
  end

  def unknown?
    !!@unknown
  end

  def name
    unknown? ? "不明金(#{@account_name})" : @account_name
  end

  def previous_flow
    @previous_flow ? @previous_flow.flow : 0
  end

end