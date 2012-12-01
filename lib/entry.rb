# -*- encoding : utf-8 -*-
module Entry

  def self.included(base)
    base.validates :amount, :numericality => {:only_integer => true, :allow_blank => true}
    base.validate :validate_amount_is_not_zero

    base.before_save :reject_if_empty
  end
  
  def reversed_amount=(ra)
    # TODO: parse_amount の位置をどうするか
    self.amount = ra.blank? ? ra : Entry::Base.parse_amount(ra).to_i * -1
  end

  def reversed_amount
    self.amount.blank? ? self.amount : self.amount.to_i * -1
  end

  # 勘定ID、金額、摘要がいずれもない場合は空とみなす
  def empty?
    account_id.blank? && amount.blank? && summary.blank?
  end

  private
  def validate_amount_is_not_zero
    errors.add :amount, "に0を指定することはできません。" if amount && amount.to_i == 0
  end

  # 空の場合は例外を発生させる
  # 通常利用では発生しないことを想定しているため検証ではなく例外発生とする
  def reject_if_empty
    raise "Empty entry can't be saved! : #{self.inspect}" if empty?
  end

end
