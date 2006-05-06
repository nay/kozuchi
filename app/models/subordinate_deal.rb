# 従属的な明細のクラス
class SubordinateDeal < Deal
  belongs_to :parent,
             :class_name => 'Deal',
             :foreign_key => 'parent_deal_id'

  def is_subordinate
    return true
  end

  def parent_for(account_id)
    return parent.has_account(account_id)
  end
  
  # TODO 表現を含んでいるが・・
  def summary
    return "#{parent.date.strftime('%Y/%m/%d')}の精算 (#{parent.summary})"
  end

end