class Flow::Plus < Flow::Base
  def flow
    unknown? ? account.unknown : account.flow
  end
end