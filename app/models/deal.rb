# 異動明細クラス。
class Deal < BaseDeal
  attr_accessor :minus_account_id, :plus_account_id, :amount
  has_many   :children,
             :class_name => 'SubordinateDeal',
             :foreign_key => 'parent_deal_id',
             :dependent => true

  # 自分の取引のなかに指定された口座IDが含まれるか
  def has_account(account_id)
    for entry in account_entries
      return true if entry.account.id == account_id
    end
    return false
  end
  
  # 子取引のなかに指定された口座IDが含まれればそれをかえす
  def child_for(account_id)
    for child in children
      return child if child.has_account(account_id)
    end
    return false
  end

  def before_save
    pre_before_save
  end

  def before_create
    create_relations
  end
  
  def before_update
    clear_relations
    create_relations
  end

  # Prepare sugar methods
  def after_find
    set_old_date
    raise "Invalid Deal Object with #{account_entries.size} entries." unless account_entries.size == 2
    
    @minus_account_id = account_entries[0].account_id
    @plus_account_id = account_entries[1].account_id
    @amount = account_entries[1].amount
  end
  
  private

  def clear_relations
    account_entries.clear
    children.clear
  end
  
  def create_relations
    # 小さいほうが前になるようにする。これにより、minus, plus, amount は値が逆でも差がなくなる
    if @amount.to_i >= 0
      account_entries.create(:user_id => user_id, :account_id => @minus_account_id, :amount => @amount.to_i*(-1))
    end
    account_entries.create(:user_id => user_id, :account_id => @plus_account_id, :amount => @amount.to_i)
    if @amount.to_i < 0
      account_entries.create(:user_id => user_id, :account_id => @minus_account_id, :amount => @amount.to_i*(-1))
    end

    # 精算ルールに従って従属行を用意する
    for i in 0..1
      account_rule = account_entries[i].account.account_rule
      if account_rule
        # どこからからルール適用口座への異動額
        new_amount = account_entries[0].account_id == account_rule.account_id ? account_entries[0].amount : account_entries[1].amount
        # 適用口座がクレジットカードなら、出金元となっているときだけルールを適用する。債権なら入金先となっているときだけ適用する。
        if (Account::ASSET_CREDIT_CARD == account_rule.account.asset_type && new_amount < 0) ||(Account::ASSET_CREDIT == account_rule.account.asset_type && new_amount > 0)
          children.create(
            :minus_account_id => account_rule.account_id,
            :plus_account_id => account_rule.associated_account_id,
            :amount => new_amount,
            :user_id => self.user_id,
            :date => self.date  >> 1,
            :summary => "",
            :confirmed => false)
        end
      end
    end
  end
  
  
end
