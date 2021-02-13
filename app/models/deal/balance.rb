# 残高確認記入行クラス

# * 登録時は、account_id, balanceをセットしてsaveする。
# * 参照時は、account_id, balanceで既存のAccountEntryのデータにアクセスできる。
class Deal::Balance < Deal::Base

  before_validation :set_user_id_to_entry
  before_create :set_date_and_daily_seq_to_entry
  before_update :rebuild_entry
  before_destroy :cache_account_id # entry より上にないといけない（entryが削除される前に実行する必要がある）
  
  has_one   :entry, :class_name => "Entry::Balance",
             :foreign_key => 'deal_id',
             :dependent => :destroy,
             :autosave => true

  after_save :update_initial_balance
  after_destroy :update_initial_balance

  delegate :account_id=, :account_id, :account, :balance=, :balance, :balance_before_type_cast, :amount, :summary, :initial_balance?, :balance_before, :summary_truncated?, to: :prepared_entry

  def balance?
    true
  end

  def build_entry
    super
    # あれば入れる。登録前にも入れる
    entry.user_id = user_id
    entry.date = date
    entry.daily_seq = daily_seq
    entry.confirmed = confirmed
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

  # amount（最初の残高以外は不明金として扱われる）を再計算して更新
  # 自分が「最初の残高」なら、最初の残高を考慮しない残高計算をする
  # AccountEntryのupdate_balanceから呼ばれる
  # これを順々にやれば残高不正は修正できると思われる
  def update_amount
    amount = entry.balance.to_i - balance_before(entry.initial_balance?)
    Entry::Base.where(id: entry.id).update_all("amount = #{amount}")
    entry.amount = amount
  end

  private

  def prepared_entry
    build_entry unless entry
    entry
  end

  # 更新時は、entryが変更されていたら必ず一度削除して作り直す
  def rebuild_entry
    return unless entry.changed?
    entry_attributes = entry.attributes.slice('account_id', 'balance')
    entry.destroy
    build_entry
    entry.attributes = entry_attributes
  end

  # 検証で利用するため user_id は先に必要となる
  def set_user_id_to_entry
    raise "no user_id" unless user_id
    entry.user_id = user_id
  end

  def set_date_and_daily_seq_to_entry
    raise "no date" unless date
    entry.date = date
    raise "no daily_seq" unless daily_seq
    entry.daily_seq = daily_seq
    entry.confirmed = confirmed
  end

  def cache_account_id
    account_id # entries を検索して account_id をキャッシュする
  end

  # 対象口座のinitial_balance値を更新する
  def update_initial_balance
    raise "no account_id" unless account_id
    initial_balance_entry = Entry::Balance.of(account_id).ordered.first
    # 現在ひとつもないなら特に仕事なし
    return unless initial_balance_entry # destroyの際はこれが起きる可能性がある
    # すでにマークがついていたら仕事なし
    return if initial_balance_entry.initial_balance?

    # マークがついていない＝状態が変わったので修正する
    Entry::Base.where(account_id: account_id).update_all(["initial_balance = ?", false])
    Entry::Base.where(id: initial_balance_entry.id).update_all(["initial_balance = ?", true])
    # オブジェクトがあるときはオブジェクトの状態も変えておく
    entry.initial_balance = true if entry && entry.id == initial_balance_entry.id
  end

end
