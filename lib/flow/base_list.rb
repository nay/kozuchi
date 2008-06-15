class Flow::BaseList < Array
  def <<(account)
    super new_flow(account)
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
  
end