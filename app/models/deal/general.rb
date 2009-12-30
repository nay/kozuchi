# 異動明細クラス。
class Deal::General < Deal::Base

  module EntriesAssociationExtension
    def build(*args)
      record = super
      record.user_id = proxy_owner.user_id
      record.date = proxy_owner.date
      record.daily_seq = proxy_owner.daily_seq
      record
    end
  end

  with_options :class_name => "Entry::General", :foreign_key => 'deal_id', :extend =>  EntriesAssociationExtension do |e|
    e.has_many :debtor_entries, :conditions => "amount >= 0", :include => :account
    e.has_many :creditor_entries, :conditions => "amount < 0", :include => :account
    e.has_many :entries, :order => "amount", :dependent => :destroy # TODO: いずれなくして base の readonly_entries を名前変更？
  end

  accepts_nested_attributes_for :debtor_entries, :creditor_entries

  before_validation :fill_amount_to_one_side
  validate :validate_entries
#  before_validation :regulate_amount
  before_update :clear_entries_before_update
  after_save :create_relations
  before_destroy :destroy_entries


  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.deal(:id => "deal#{self.id}", :date => self.date_as_str, :position => self.daily_seq, :confirmed => self.confirmed) do
      xml.description XMLUtil.escape(self.summary)
      xml.entries do
        # include で検索している前提
        readonly_entries.each{|e| e.to_xml(:builder => xml, :skip_instruct => true)}
      end
    end
  end

  def to_csv_lines
    csv_lines = [["deal", id, date_as_str, daily_seq, "\"#{summary}\"", confirmed].join(',')]
    readonly_entries.each{|e| csv_lines << e.to_csv}
    csv_lines
  end

  # 貸し方勘定名を返す
  def debtor_account_name
    debtor_entries # 一度全部とる
    debtor_entries.size == 1 ? debtor_entries.first.account.name : "諸口"
  end

  def debtor_amount
    debtor_entries.inject(0){|value, entry| value += entry.amount.to_i}
  end
  # 借り方勘定名を返す
  def creditor_account_name
    # TODO: 実装はあとで変えたい
    entries.detect{|e| e.amount < 0}.account.name
  end

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
    !entries.detect{|e| e.settlement_attached?}.nil?
  end

  # 相手勘定名を返す
  def mate_account_name_for(account_id)
    # TODO: 諸口対応、不正データ対応
    entries.detect{|e| e.account_id != account_id}.account.name
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
    results = find_by_sql("select summary as summary, max(date) as date from deals where user_id = #{user_id} and type='General' and summary like '#{summary_key}%' group by summary limit #{limit}")
    return [] if results.size == 0
    conditions = ""
    for r in results
      conditions += " or " unless conditions.empty?
      conditions += "(summary = '#{r.summary}' and date = '#{r.date}')"
    end
    return Deal::General.find(:all, :conditions => "user_id = #{user_id} and (#{conditions})")
    rescue
     return []
    end
  end

  # 自分の取引のなかに指定された口座IDが含まれるか
  def has_account(account_id)
    for entry in entries
      return true if entry.account.id == account_id
    end
    return false
  end
  
  def entry(account_id)
    raise "no account_id in Deal::General.entry()" unless account_id
    r = entries.detect{|e| e.account_id.to_s == account_id.to_s}
#    raise "no account_entry in deal #{self.id} with account_id #{account_id}" unless r
    r
  end

  private

  def validate_entries

    # amount 合計が 0 でなければならない
    sum = debtor_entries.inject(0) {|r, e| r += e.amount.to_i} + creditor_entries.inject(0) {|r, e| r += e.amount.to_i}
    errors.add_to_base("借方、貸方が同額ではありません。") unless sum == 0
  end


  # before_destroy
  def destroy_entries
    entries.destroy_all # account_entry の before_destroy 処理を呼ぶ必要があるため明示的に
  end

#  def regulate_amount
#    # もし金額にカンマが入っていたら正規化する
#    self.amount = self.amount.gsub(/,/,'') if self.amount.class == String
#  end

  def clear_entries_before_update
    for entry in entries
      # この取引の勘定でなくなっていたら、entryを消す
      if self.plus_account_id.to_i != entry.account_id.to_i && self.minus_account_id.to_i != entry.account_id.to_i
#        p "plus_account_id = #{self.plus_account_id} . minus_account_id = #{self.minus_account_id}. this_entry_account_id = #{entry.account_id}"
        entry.destroy
      end
    end
  end

  def clear_relations
    entries.clear
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
      entry = entries.build(
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
    
    entries(true)

  end
  
  def refreshed?
    return true if new_record?
    @refreshed ||= false
    @refreshed
  end
  
  # 高速化のため、after_find でやっていたのを lazy にしてここへ
  def refresh_account_info
    @refreshed = true
# TODO:
#    p "Invalid Deal Object #{self.id} with #{entries.size} entries." unless entries.size == 2
    return unless entries.size == 2
    
    for et in entries
      if et.amount >= 0
        @plus_account_id = et.account_id
        @amount = et.amount
      else
        @minus_account_id = et.account_id
      end
    end
        
  end

  def fill_amount_to_one_side
    if creditor_entries.size == 1 && creditor_entries.first.amount.nil? && !debtor_entries.any?{|e| e.amount.nil?}
      creditor_entries.first.amount = debtor_entries.inject(0) {|r, e| r += e.amount.to_i} * -1
    elsif debtor_entries.size == 1 && debtor_entries.first.amount.nil? && !creditor_entries.any?{|e| e.amount.nil?}
      debtor_entries.first.amount = creditor_entries.inject(0) {|r, e| r += e.amount.to_i} * -1
    end
  end

end
