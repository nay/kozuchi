# 異動明細クラス。
class Deal < BaseDeal
  has_many   :children,
             :class_name => 'SubordinateDeal',
             :foreign_key => 'parent_deal_id',
             :dependent => :destroy

  # 貸し方勘定名を返す
  def debtor_account_name
    # TODO: 実装はあとで変えたい
    account_entries.detect{|e| e.amount >= 0}.account.name
  end
  def debtor_amount
    # TODO: 実装はあとで変えたい
    account_entries.detect{|e| e.amount >= 0}.amount
  end
  # 借り方勘定名を返す
  def creditor_account_name
    # TODO: 実装はあとで変えたい
    account_entries.detect{|e| e.amount < 0}.account.name
  end


  after_save :create_relations

  def plus_account_id
    refresh_account_info unless refreshed?
    @plus_account_id
  end
  def plus_account_id=(id)
    refresh_account_info unless refreshed?
    @plus_account_id = id
  end
  def minus_account_id
    refresh_account_info unless refreshed?
    @minus_account_id
  end
  def minus_account_id=(id)
    refresh_account_info unless refreshed?
    @minus_account_id = id
  end
  def amount
    refresh_account_info unless refreshed?
    @amount
  end
  def amount=(a)
    refresh_account_info unless refreshed?
    @amount = a
  end

  def settlement_attached?
    !account_entries.detect{|e| e.settlement_attached?}.nil?
  end

  # 相手勘定名を返す
  def mate_account_name_for(account_id)
    # TODO: 諸口対応、不正データ対応
    account_entries.detect{|e| e.account_id != account_id}.account.name
  end

  def before_validation
    # もし金額にカンマが入っていたら正規化する
    self.amount = self.amount.gsub(/,/,'') if self.amount.class == String
  end

  def validate
    errors.add_to_base("同じ口座から口座への異動は記録できません。 account_id = #{self.minus_account_id}") if self.minus_account_id && self.plus_account_id && self.minus_account_id.to_i == self.plus_account_id.to_i
    errors.add_to_base("金額が0となっています。") if self.amount && self.amount.to_i == 0 # TODO
    # もし精算データにひもづいているのに口座が対応していなくなったらエラー（TODO: 将来はかしこくするが現時点では精算ルール側でなおさないとだめにする）
    # errors.add_to_base("#{self.settlement.account.name} の精算データに含まれているため、変更できません。") if self.settlement && self.minus_account_id != self.settlement.account_id && self.plus_account_id != self.settlement.account_id
    # TODO: 金額不一致の検証
  end

  # summary の前方一致で検索する
  def self.search_by_summary(user_id, summary_key, limit)
    begin
    return [] if summary_key.empty?
    # まず summary と 日付(TODO: created_at におきかえたい)のセットを返す
    p "search_by_summary : summary_key = #{summary_key}"
    results = find_by_sql("select summary as summary, max(date) as date from deals where user_id = #{user_id} and type='Deal' and summary like '#{summary_key}%' group by summary limit #{limit}")
    p "results.size = #{results.size}"
    return [] if results.size == 0
    conditions = ""
    for r in results
      conditions += " or " unless conditions.empty?
      conditions += "(summary = '#{r.summary}' and date = '#{r.date}')"
    end
    return Deal.find(:all, :conditions => "user_id = #{user_id} and (#{conditions})")
    rescue => err
    p err
    p err.backtrace
    return []
    end
  end

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

  def before_update
    clear_entries_before_update    
    children.clear
  end

  # Prepare sugar methods
  def after_find
    set_old_date
    # account_enrties がまだできていないときにやるとパフォーマンスロスになるので refresh_account_infoに移動
#    p "Invalid Deal Object #{self.id} with #{account_entries.size} entries." unless account_entries.size == 2
##    raise "Invalid Deal Object #{self.id} with #{account_entries.size} entries." unless account_entries.size == 2
#    return unless account_entries.size == 2
#    
#    for et in account_entries
#      if et.amount >= 0
#        @plus_account_id = et.account_id
#        @amount = et.amount
#      else
#        @minus_account_id = et.account_id
#      end
#    end
  end
  
  def before_destroy
    account_entries.destroy_all # account_entry の before_destroy 処理を呼ぶ必要があるため明示的に
    # フレンドリンクまたは本体までを消す
 #   clear_friend_deals
  end

  # ↑↑  call back methods  ↑↑
  
  def entry(account_id)
    raise "no account_id in Deal.entry()" unless account_id
    r = account_entries.detect{|e| e.account_id.to_s == account_id.to_s}
#    raise "no account_entry in deal #{self.id} with account_id #{account_id}" unless r
    r
  end

  private

  def clear_entries_before_update
    for entry in account_entries
      # この取引の勘定でなくなっていたら、entryを消す
      if self.plus_account_id.to_i != entry.account_id.to_i && self.minus_account_id.to_i != entry.account_id.to_i
        p "plus_account_id = #{self.plus_account_id} . minus_account_id = #{self.minus_account_id}. this_entry_account_id = #{entry.account_id}" 
        entry.destroy
      end
    end
  end

  def clear_relations
    account_entries.clear
    children.clear
  end

  def update_account_entry(is_minus, is_first)
    if is_minus
      entry_account_id = self.minus_account_id
      entry_amount = self.amount.to_i*(-1)
      another_entry_account = is_first ? Account::Base.find(self.plus_account_id) : nil
      # second に上記をわたしても無害だが不要なため処理を省く
    else
      entry_account_id = self.plus_account_id
      entry_amount = self.amount.to_i
      another_entry_account = is_first ? Account::Base.find(self.minus_account_id) : nil
      # second に上記をわたしても無害だが不要なため処理を省く
    end
    
    entry = entry(entry_account_id)
    if !entry
      entry = account_entries.build(
                :amount => entry_amount,
                :another_entry_account => another_entry_account)
      entry.account_id = entry_account_id
      entry.save # TODO: save!でなくていいの？
    else
      # 金額、日付が変わったときは変わったとみなす。サマリーだけ変えても影響なし。
      # entry.save がされるということは、リンクが消されて新しくDeal が作られるということを意味する。
      if entry_amount != entry.amount || self.old_date != self.date
#        # すでにリンクがある場合、消して作り直す際は変更前のリンク先口座を優先的に選ぶ。
#        if entry.linked_account_entry
#          entry.account_to_be_connected = entry.linked_account_entry.account
#        end
        entry.amount = entry_amount
        entry.another_entry_account = another_entry_account
        entry.save!
      end
    end
    return entry
  end
  
  def create_relations
    # 当該account_entryがなくなっていたら消す。金額が変更されていたら更新する。あって金額がそのままなら変更しない。
    # 小さいほうが前になるようにする。これにより、minus, plus, amount は値が逆でも差がなくなる
    return unless self.amount # TODO: 間接でないのをとりあえずこれで判断
    entry = nil
    entry = update_account_entry(true, true) if self.amount.to_i >= 0     # create minus
    entry = update_account_entry(false, !entry) # create plus
    update_account_entry(true, false) if self.amount.to_i < 0   # create_minus
    
    account_entries(true)

  end
  
  def refreshed?
    return true if new_record?
    @refreshed ||= false
    @refreshed
  end
  
  # 高速化のため、after_find でやっていたのを lazy にしてここへ
  def refresh_account_info
    @refreshed = true
    p "Invalid Deal Object #{self.id} with #{account_entries.size} entries." unless account_entries.size == 2
    return unless account_entries.size == 2
    
    for et in account_entries
      if et.amount >= 0
        @plus_account_id = et.account_id
        @amount = et.amount
      else
        @minus_account_id = et.account_id
      end
    end
        
  end
  
end
