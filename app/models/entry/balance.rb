# -*- encoding : utf-8 -*-
class Entry::Balance < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::Balance',
             :foreign_key => 'deal_id'


  scope :without_initial, :conditions => {:initial_balance => false}

  def summary
    '残高確認'
  end

  def partner_account_name
    '不明金'
  end
end
