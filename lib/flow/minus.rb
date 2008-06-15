class Flow::Minus < Flow::Base
  def flow
    unknown? ? account.unknwon * -1 : account.flow * -1
  end
end