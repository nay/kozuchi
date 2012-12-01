# -*- encoding : utf-8 -*-
module Entry

  def self.included(base)
    base.validates :amount, :numericality => {:only_integer => true}
    base.validate :validate_amount_is_not_zero
  end
  
  def reversed_amount=(ra)
    # TODO: parse_amount の位置をどうするか
    self.amount = ra.blank? ? ra : Entry::Base.parse_amount(ra).to_i * -1
  end

  def reversed_amount
    self.amount.blank? ? self.amount : self.amount.to_i * -1
  end

  private
  def validate_amount_is_not_zero
    errors.add :amount, "に0を指定することはできません。" if amount && amount.to_i == 0
  end

end
