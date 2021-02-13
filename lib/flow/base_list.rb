class Flow::BaseList < Array

  def new_flow(account, previous)
    self.class.element_class.new(
      account,
      (account.respond_to?(:unknown) ? account.unknown : account.flow),
      account.respond_to?(:unknown),
      self,
      previous ? new_flow(previous, nil) : nil)
  end
  def new_zero_flow(previous)
    self.class.element_class.new(
      previous,
      0,
      previous.respond_to?(:unknown),
      self,
      new_flow(previous, nil))
  end

  def add_with_previous(account, previous)
    self << (account ? new_flow(account, previous) : new_zero_flow(previous))
  end

  def plus_sum
    sum(true)
  end
  
  def sum(plus_only = false)
    result = 0
    each do |f|
      next if plus_only && f.flow < 0
      result += f.flow
    end
    result
  end

  def previous_sum(plus_only = false)
    result = 0
    each do |f|
      next if plus_only && f.previous_flow < 0
      result += f.previous_flow
    end
    result
  end
  
end