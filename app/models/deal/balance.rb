# -*- encoding : utf-8 -*-
# 残高確認記入行クラス

# * 登録時は、account_id, balanceをセットしてsaveする。
# * 参照時は、account_id, balanceで既存のAccountEntryのデータにアクセスできる。
class Deal::Balance < Deal::Base

  before_update :rebuild_entry
  before_destroy :cache_account_id # entries より上にないといけない（entriesが削除される前に実行する必要がある）
  has_one   :entry, :class_name => "Entry::Balance",
             :foreign_key => 'deal_id',
             :dependent => :destroy,
             :autosave => true

  attr_writer :account_id, :balance
  validates_presence_of :account_id
  validates_presence_of :balance, :message => '残高を入力してください。'
  before_create :set_requirements_to_entry
  before_update :set_requirements_to_entry
  after_save :reset_attributes, :update_initial_balance
  after_destroy :update_initial_balance

  delegate :account_id=, :account_id, :account, :balance=, :balance, :balance_before_type_cast, :amount, :summary, :to => :prepared_entry

  def build_entry
    super
    # あれば入れる。登録前にも入れる
    entry.user_id = user_id
    entry.date = date
    entry.daily_seq = daily_seq
    entry
  end

  def summary_unified?
    true
  end

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.balance(:id => "balance#{self.id}", :date => self.date_as_str, :position => self.daily_seq, :account => "account#{self.account_id}") do
      xml.description XMLUtil.escape(self.summary)
      xml.amount self.readonly_entries.first.try(:balance)
    end
  end

  def to_csv
    ["balance", self.id, date_as_str, daily_seq, account_id, balance].join(",")
  end

  def initial_balance?
    raise "no entry" unless entry
    entry.initial_balance?
  end
  
  # amount（最初の残高以外は不明金として扱われる）を再計算して更新
  # 自分が「最初の残高」なら、最初の残高を考慮しない残高計算をする
  # AccountEntryのupdate_balanceから呼ばれる
  # これを順々にやれば残高不正は修正できると思われる
  def update_amount
    e = entry
#    p "balance_before(true) = #{balance_before(true)}"
#    p "balance_before(false) = #{balance_before(false)}"
    amount = e.balance.to_i - balance_before(e.initial_balance?)
    Entry::Base.update_all("amount = #{amount}", ["id = ?", e.id])
#    p "update_amount : amount = #{amount}"
    entry.amount = amount
    # このAccountEntryについて、以降の残高を調整する必要はないはずなのでコールバック阻止（ループ防止）
#    e.update_attribute(:amount, amount)
  end

  private

  def prepared_entry
    build_entry unless entry
    entry
  end

  def reset_attributes
#    @balance = nil
#    @account_id = nil
    # should be got from entry if required
  end

  # 更新時は、entryが変更されていたら必ず一度削除して作り直す
  def rebuild_entry
    return unless entry.changed?
    entry_attributes = entry.attributes.slice('account_id', 'balance')
    entry.destroy
    build_entry
    entry.attributes = entry_attributes
    # 残りは set_requirements_to_entry が入れる
  end

  def set_requirements_to_entry
    raise "no user_id" unless user_id
    entry.user_id = user_id
    raise "no date" unless date
    entry.date = date
    raise "no daily_seq" unless daily_seq
    entry.daily_seq = daily_seq

    entry.amount = calc_amount
  end

  # TODO: entryへ移動
  def calc_amount
    current_initial_balance = Entry::Base.find_by_account_id_and_initial_balance(self.account_id, true, :include => :deal)
    this_will_be_initial = !current_initial_balance || current_initial_balance.deal.date > self.date || (current_initial_balance.deal.date == self.date && current_initial_balance.deal.daily_seq > self.daily_seq)
    Entry::Base.parse_amount(balance).to_i - balance_before(this_will_be_initial)
  end

  def cache_account_id
    account_id # entries を検索して account_id をキャッシュする
  end

  # 対象口座のinitial_balance値を更新する
  def update_initial_balance
    raise "no account_id" unless account_id
#    conditions = ["entries.account_id = ? and deals.type='Balance'", account_id]
#    initial_balance_entry = Entry::Base.find(:first,
#      :joins => "inner join deals on deals.id = entries.deal_id",
#      :conditions => conditions, :order => "deals.date, deals.daily_seq", :readonly => false)
    initial_balance_entry = Entry::Balance.of(account_id).ordered.first
    # 現在ひとつもないなら特に仕事なし
    return unless initial_balance_entry # destroyの際はこれが起きる可能性がある
    # すでにマークがついていたら仕事なし
    return if initial_balance_entry.initial_balance?

    # マークがついていない＝状態が変わったので修正する
    Entry::Base.update_all(["initial_balance = ?", false], ["account_id = ?", account_id])
    Entry::Base.update_all(["initial_balance = ?", true], ["id = ?", initial_balance_entry.id])
    # オブジェクトがあるときはオブジェクトの状態も変えておく
    entry.initial_balance = true if entry && entry.id == initial_balance_entry.id
  end
  
  
  def balance_before(ignore_initial = false)
    raise "date or daily_seq is nil!" unless self.date && self.daily_seq
    account.balance_before(self.date, self.daily_seq, ignore_initial)
  end


end