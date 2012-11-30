# -*- encoding : utf-8 -*-
module Entry
  
  def reversed_amount=(ra)
    # TODO: parse_amount の位置をどうするか
    self.amount = ra.blank? ? ra : Entry::Base.parse_amount(ra).to_i * -1
  end

  def reversed_amount
    self.amount.blank? ? self.amount : self.amount.to_i * -1
  end
  
end
