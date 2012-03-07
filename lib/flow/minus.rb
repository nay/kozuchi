# -*- encoding : utf-8 -*-
class Flow::Minus < Flow::Base
  def flow
    @flow * -1
  end
end