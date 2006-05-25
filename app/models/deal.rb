# 異動明細クラス。
class Deal < BaseDeal
  attr_accessor :minus_account_id, :plus_account_id, :amount, :minus_account_friend_link_id
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

  # ↓↓  call back methods  ↓↓

  def before_save
    pre_before_save
  end

  def after_save
    p "after_save #{self.id}"
    create_relations
  end
  
  def before_update
    clear_entries_before_update    
    children.clear
#    create_relations
  end

  # Prepare sugar methods
  def after_find
#    p "after_find #{self.id}"
    set_old_date
    p "Invalid Deal Object #{self.id} with #{account_entries.size} entries." unless account_entries.size == 2
#    raise "Invalid Deal Object #{self.id} with #{account_entries.size} entries." unless account_entries.size == 2
    return unless account_entries.size == 2
    
    @minus_account_id = account_entries[0].account_id
    @plus_account_id = account_entries[1].account_id
    @amount = account_entries[1].amount
  end
  
  def before_destroy
    account_entries.destroy_all # account_entry の before_destroy 処理を呼ぶ必要があるため明示的に
    # フレンドリンクまたは本体までを消す
 #   clear_friend_deals
  end
  
  def entry(account_id)
    for entry in account_entries
      return entry if entry.account_id.to_i == account_id.to_i
    end
    return nil
  end

  # ↑↑  call back methods  ↑↑
  
  private

  def clear_entries_before_update
    for entry in account_entries
      if @plus_account_id.to_i != entry.account_id.to_i && @minus_account_id.to_i != entry.account_id.to_i
        p "plus_account_id = #{@plus_account_id} . minus_account_id = #{@minus_account_id}. this_entry_account_id = #{entry.account_id}" 
        entry.destroy
      end
    end
  end

  def clear_relations
    account_entries.clear
    children.clear
  end

  def update_account_entry(is_minus)
    if is_minus
      entry_account_id = @minus_account_id
      entry_amount = @amount.to_i*(-1)
      entry_friend_link_id = @minus_account_friend_link_id
    else
      entry_account_id = @plus_account_id
      entry_amount = @amount.to_i
      entry_friend_link_id = nil
    end
    
    entry = entry(entry_account_id)
    if !entry
      account_entries.create(:user_id => user_id, :account_id => entry_account_id, :friend_link_id => entry_friend_link_id, :amount => entry_amount)
    else
      if entry.amount != entry_amount
        entry.amount = entry_amount
        entry.save!
      end
    end
  end
  
  def create_relations
    # 当該account_entryがなくなっていたら消す。金額が変更されていたら更新する。あって金額がそのままなら変更しない。
    # 小さいほうが前になるようにする。これにより、minus, plus, amount は値が逆でも差がなくなる
    update_account_entry(true) if @amount.to_i >= 0     # create minus
    update_account_entry(false)                         # create plus
    update_account_entry(true) if @amount.to_i < 0   # create_minus

    for i in 0..1
      account_rule = account_entries[i].account.account_rule
      # 精算ルールに従って従属行を用意する
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
            :date => account_rule.payment_date(self.date),
#            :date => self.date  >> 1,
            :summary => "",
            :confirmed => false)
        end
      end
    end
  end
  
end
