class Flow::MinusList < Flow::BaseList
  def new_flow(account)
    Flow::Minus.new(account, self)
  end
end