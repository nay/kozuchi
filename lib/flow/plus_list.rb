class Flow::PlusList < Flow::BaseList
  def new_flow(account)
    Flow::Plus.new(account, self)
  end
end