class Entry::General < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::General',
             :foreign_key => 'deal_id'
  belongs_to :settlement
  belongs_to :result_settlement, :class_name => 'Settlement', :foreign_key => 'result_settlement_id'

  before_destroy :assert_no_settlement

  validates_numericality_of :amount, :only_integer => true

  validate :validate_amount_is_not_zero

  attr_writer :partner_account_name # 相手勘定名

  def partner_account_name
    @parter_account_name ||= deal.partner_account_name_of(self)
  end

  def reversed_amount=(ra)
    self.amount = ra.blank? ? ra : ra.to_i * -1
  end

  def reversed_amount
    self.amount.blank? ? self.amount : self.amount.to_i * -1
  end

  # 精算から呼ぶ。リンクするはずのentryが正しくリンクするようにする。
  def ensure_linking(receiver)
    unless linked_account_entry
      # 自分側からリンクがきれてるのに相手に残っている場合は異常ケース。いったん相手とunlinkする
      receiver.unlink_deal_for(user_id, deal_id) if receiver.linked_deal_for(user_id, deal_id)
      linked_entries = receiver.link_deal_for(user_id, deal_id, deal.entries_hash_for(receiver.id), deal.summary, date)
      for entry_id, ex_info in linked_entries
        Entry::Base.update_all("linked_ex_entry_id = #{ex_info[:entry_id]}, linked_ex_deal_id = #{ex_info[:deal_id]}, linked_user_id = #{receiver.id}",  "id = #{entry_id}")
      end
      reload
      raise "no linked_ex_entrt_id" unless linked_account_entry
    end
    self
  end

  private
  def validate_amount_is_not_zero
    errors.add :amount, "に0を指定することはできません。" if amount && amount.to_i == 0
  end

end
