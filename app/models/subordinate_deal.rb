# 従属的な明細のクラス
class SubordinateDeal < Deal
  belongs_to :parent,
             :class_name => 'Deal',
             :foreign_key => 'parent_deal_id'

  def parent_for(account_id)
    return parent.has_account(account_id)
  end

end