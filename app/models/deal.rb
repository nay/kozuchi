# 異動明細クラス。
# TODO: 最終的に精算データが空になったらなくすとか、削除できないなどの処理をしたい。削除しつづけるとおかしな精算データができる恐れあり。
class Deal < BaseDeal
  attr_accessor :minus_account_friend_link_id, :plus_account_friend_link_id
  has_many   :children,
             :class_name => 'SubordinateDeal',
             :foreign_key => 'parent_deal_id',
             :dependent => true

  after_save :create_relations, :create_children

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

  def another_account_entry(entry)
    account_entries.detect{|e| e.account_id.to_s != entry.account.id.to_s}
  end

  def before_validation
    # もし金額にカンマが入っていたら正規化する
    self.amount = self.amount.gsub(/,/,'') if self.amount.class == String
  end

  def validate
    errors.add_to_base("同じ口座から口座への異動は記録できません。") if self.minus_account_id && self.plus_account_id && self.minus_account_id.to_i == self.plus_account_id.to_i
    errors.add_to_base("金額が0となっています。") if self.amount.to_i == 0
    # もし精算データにひもづいているのに口座が対応していなくなったらエラー（TODO: 将来はかしこくするが現時点では精算ルール側でなおさないとだめにする）
    # errors.add_to_base("#{self.settlement.account.name} の精算データに含まれているため、変更できません。") if self.settlement && self.minus_account_id != self.settlement.account_id && self.plus_account_id != self.settlement.account_id
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

  def update_account_entry(is_minus, is_first, deal_link_for_second)
    deal_link_id_for_second = deal_link_for_second ? deal_link_for_second.id : nil
    if is_minus
      entry_account_id = self.minus_account_id
      entry_amount = self.amount.to_i*(-1)
      entry_friend_link_id = @minus_account_friend_link_id
      entry_friend_link_id ||= deal_link_id_for_second if !is_first
      another_entry_account = is_first ? Account::Base.find(self.plus_account_id) : nil
      # second に上記をわたしても無害だが不要なため処理を省く
    else
      entry_account_id = self.plus_account_id
      entry_amount = self.amount.to_i
      entry_friend_link_id = @plus_account_friend_link_id
      entry_friend_link_id ||= deal_link_id_for_second if !is_first
      another_entry_account = is_first ? Account::Base.find(self.minus_account_id) : nil
      # second に上記をわたしても無害だが不要なため処理を省く
    end
    
    entry = entry(entry_account_id)
    if !entry
      entry = account_entries.create(:user_id => user_id,
                :account_id => entry_account_id,
                :friend_link_id => entry_friend_link_id,
                :amount => entry_amount,
                :another_entry_account => another_entry_account)
    else
      # 金額、日付が変わったときは変わったとみなす。サマリーだけ変えても影響なし。
      # entry.save がされるということは、リンクが消されて新しくDeal が作られるということを意味する。
      if entry_amount != entry.amount || self.old_date != self.date
        # すでにリンクがある場合、消して作り直す際は変更前のリンク先口座を優先的に選ぶ。
        if entry.linked_account_entry
          entry.account_to_be_connected = entry.linked_account_entry.account
        end
        entry.amount = entry_amount
        entry.another_entry_account = another_entry_account
        entry.friend_link_id = deal_link_id_for_second if !is_first && deal_link_id_for_second
        entry.save!
      end
    end
    return entry
  end
  
  def create_relations
    # 当該account_entryがなくなっていたら消す。金額が変更されていたら更新する。あって金額がそのままなら変更しない。
    # 小さいほうが前になるようにする。これにより、minus, plus, amount は値が逆でも差がなくなる
    entry = nil
    entry = update_account_entry(true, true, nil) if self.amount.to_i >= 0     # create minus
    entry = update_account_entry(false, !entry, entry ? entry.new_plus_link : nil) # create plus
    update_account_entry(true, false, entry.new_plus_link) if self.amount.to_i < 0   # create_minus
    
    account_entries(true)

  end
  
  def create_children
    for i in 0..1
      next unless account_entries[i].account.kind_of? Account::Asset
      account_rule = account_entries[i].account.account_rule(true)
      # 精算ルールに従って従属行を用意する
      if account_rule
        # どこからからルール適用口座への異動額
        new_amount = account_entries[i].amount
        # 適用口座がクレジットカードなら、出金元となっているときだけルールを適用する。債権なら入金先となっているときだけ適用する。
        if (account_rule.account.kind_of?(Account::CreditCard) && new_amount < 0) ||(account_rule.account.kind_of?(Account::Credit) && new_amount > 0)
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
    
    require_revert = false
    for et in account_entries
      if et.amount >= 0
        @plus_account_id = et.account_id
        @amount = et.amount
      else
        @minus_account_id = et.account_id
        require_revert = true if et.account.type_in?(:expense)
      end
    end
    
    if require_revert
      plus = @plus_account_id
      @plus_account_id = @minus_account_id
      @minus_account_id = plus
      @amount *= -1
    end
    
  end
  
end
