class Entry::General < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::General',
             :foreign_key => 'deal_id'
  belongs_to :settlement
  belongs_to :result_settlement, :class_name => 'Settlement', :foreign_key => 'result_settlement_id'

  before_destroy :assert_no_settlement

  validates_numericality_of :amount, :only_integer => true

  validate :validate_amount_is_not_zero

  def reversed_amount=(ra)
    self.amount = ra.blank? ? ra : ra.to_i * -1
  end

  def reversed_amount
    self.amount.blank? ? self.amount : self.amount.to_i * -1
  end

  private
  def validate_amount_is_not_zero
    errors.add :amount, "に0を指定することはできません。" if amount && amount.to_i == 0
  end

end
