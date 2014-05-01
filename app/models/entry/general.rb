# -*- encoding : utf-8 -*-
class Entry::General < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::General',
             :foreign_key => 'deal_id'
  belongs_to :settlement
  belongs_to :result_settlement, :class_name => 'Settlement', :foreign_key => 'result_settlement_id'

  include ::Entry

  validates :amount, :presence => true
  before_destroy :assert_no_settlement

  attr_writer :partner_account_name # 相手勘定名

  def partner_account_name
    @parter_account_name ||= deal.partner_account_name_of(self)
  end

  # 精算から呼ぶ。リンクするはずのentryが正しくリンクするようにする。
  def ensure_linking(receiver)
    unless linked_account_entry
      # 自分側からリンクがきれてるのに相手に残っている場合は異常ケース。いったん相手とunlinkする
      receiver.unlink_deal_for(user_id, deal_id) if receiver.linked_deal_for(user_id, deal_id)
      linked_entries = receiver.link_deal_for(user_id, deal_id, deal.entries_hash_for(receiver.id), deal.summary_mode, deal.summary, date)
      for entry_id, ex_info in linked_entries
        Entry::Base.where(id: entry_id).update_all("linked_ex_entry_id = #{ex_info[:entry_id]}, linked_ex_deal_id = #{ex_info[:deal_id]}, linked_user_id = #{receiver.id}")
      end
      reload
      raise "no linked_ex_entrt_id" unless linked_account_entry
    end
    self
  end

  # attributes と内容が等しいかを調べる
  def matched_with_attributes?(attributes)
    attributes[:account_id].to_s == account_id.to_s && (Entry::Base.parse_amount(attributes[:amount]).to_s == amount.to_s || Entry::Base.parse_amount(attributes[:reversed_amount]).to_s == (amount * -1).to_s )
  end

end
