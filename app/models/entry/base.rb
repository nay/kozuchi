# １口座への１記入を表す
class Entry::Base < ApplicationRecord
  self.table_name = 'account_entries'
  unsavable

  include Booking
  include Entry::SummaryTruncation

  MAX_LINE_NUMBER = 999 # 処理の都合上、上限があったほうが安心なため片側最大行数を決める

  belongs_to :account,
             :class_name => 'Account::Base',
             :foreign_key => 'account_id'

  # TODO: account.deals を使っているところのためにとりあえず
  belongs_to :deal,
             :class_name => 'Deal::Base',
             :foreign_key => 'deal_id'

  belongs_to :user # to_s で使う

  # General だけ関係するが Account::Baseからの関連で利用することを想定してここで定義
  belongs_to :result_settlement, :class_name => 'Settlement', :foreign_key => 'result_settlement_id'

  before_validation :error_if_account_is_is_chanegd # 最初にやる
  validates :account_id, :presence => true
  validate :validate_account_id_is_users
  validates :line_number, :numericality => {:greater_than_or_equal_to => 0, :less_than_or_equal_to => MAX_LINE_NUMBER }
  # deal_id, creditor, line_number の一意性はユーザーがコントロールすることではないので検証はせず、DB任せにする

  before_save :copy_deal_attributes
  before_update :set_next_balance_entry_before_move # before_saveより後に呼ばれる
  # check_amount_exists は 派生クラスの before_create (before_saveよりおそい) より後に行う必要があるため after_save で
  after_save :check_amount_exists, :update_balance #, #:request_linking

  after_destroy :update_balance #, :request_unlinking

  attr_accessor :account_to_be_connected, :another_entry_account, :pure_balance
  attr_accessor :skip_linking # 要請されて作る場合、リンクしにいくのは不要なので
  attr_reader :new_plus_link
#  attr_protected :user_id, :deal_id, :date, :daily_seq, :settlement_id, :result_settlement_id

  attr_writer :skip_unlinking

  scope :confirmed, -> { where(confirmed: true) }
  scope :date_from, ->(d) { where("date >= ?", d) } # TODO: 名前バッティングで from → date_from にした
  scope :before, ->(d) { where("date < ?", d) }
  scope :before_or_initial, ->(d) { where("account_entries.date < ? or account_entries.initial_balance = ?", d, true) }
  scope :ordered, -> { order(:date, :daily_seq) }
  # TODO: on にして deal と仕様を揃えたい
  scope :of, ->(account_id) { where(account_id: account_id) }
  scope :after, ->(e) { where("date > ? or (date = ? and daily_seq > ?)", e.date, e.date, e.daily_seq) }
  scope :in_a_time_between, ->(from, to) { where("account_entries.date >= ? and account_entries.date <= ?", from, to) }
  scope :not_initial_balance, -> { where(initial_balance: false) }
  scope :unsettled, -> { where(settlement_id: nil, result_settlement_id: nil) }

  delegate :year, :month, :day, :to => :date

  belongs_to :linked_user, :class_name => 'User', :foreign_key => 'linked_user_id'

  def any_settlement_id
    settlement_id || result_settlement_id
  end

  # TODO: Dealのconfirmed?が変わったときにEntryのセーブ系コールバックが呼ばれないと残高がおかしくなるため、強制的に更新させる
  # Entryにもconfirmed?を持たせるようにして、Dirtyを効率的に使うようにしたい
  def changed_for_autosave?
    true
  end

  def balance?
    !!balance
  end

  # StringならString のまま 前後のスペースを削除して , をとる
  def self.parse_amount(value)
    value.kind_of?(String) ? value.strip.gsub(/,/, '') : value
  end

  def amount=(a)
    self[:amount] = self.class.parse_amount(a)
  end

  def to_s
    "Entry:#{self.id}:#{object_id}(#{user ? user.login : user_id} : #{deal_id} : #{account ? account.name : account_id} : #{amount} : #{!!marked_for_destruction?})"
  end

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml_attributes = {:account => "account#{self.account_id}"}
    xml_attributes[:settlement] = "settlement#{self.settlement_id}" unless self.settlement_id.blank?
    xml_attributes[:result_settlement] = "settlement#{self.result_settlement_id}" unless self.result_settlement_id.blank?
    xml_attributes[:summary] = XMLUtil.escape(summary) if summary.present?
    xml.entry(amount, xml_attributes)
  end

  def to_csv
    ["entry", self.deal_id, self.account_id, self.settlement_id, self.result_settlement_id, amount, "\"#{summary}\""].join(',')
  end

  # 精算が紐付いているかどうかを返す。外部キーを見るだけで実際に検索は行わない。
  def settlement_attached?
    not (self.settlement_id.blank? && self.result_settlement_id.blank?)
  end

  # 相手勘定名を返す
  def mate_account_name
    raise AssociatedObjectMissingError, "no deal" unless deal
    deal.mate_account_name_for(self)
  end

  # リンクされたaccount_entry を返す
  # TODO: 廃止する
  def linked_account_entry
    linked_ex_entry_id ? Entry::Base.find_by(id: linked_ex_entry_id) : nil
  end

  def after_confirmed
    update_balance
  end

  def update_links_without_callback
    raise "new_record!" if new_record?
    Entry::Base.where(id: id).update_all("linked_ex_entry_id = #{linked_ex_entry_id}, linked_ex_deal_id = #{linked_ex_deal_id}, linked_user_id = #{linked_user_id}")
  end

  private

  def check_amount_exists
    # Entry::General では検証で防ぐ。Entry::Balanceの場合は検証を突破して自動で入れるため、ここでチェックする
    raise "no amount in #{inspect}" if amount.blank?
  end

  def error_if_account_is_is_chanegd
    raise "account_id must not be changed!" if !new_record? && changed.include?('account_id')
  end

  def validate_account_id_is_users
    return true if !account_id
    unless account
      errors.add(:account_id, "が見つかりません。")
      return true
    end
    # user_id がnilのときは別のエラーになるのでここで比較しない
    errors.add(:account_id, "が不正です。") if !user_id.nil? && account.user_id.to_i != user_id.to_i
  end

  # TODO: Dealからもセットしているので要らないかとおもったが外すと結構動かないので精査が必要
  def copy_deal_attributes
    # 基本的にDealからコピーするがDealがないケースも許容する
    if deal && deal.kind_of?(Deal::General) # TODO: 残高では常に作り直す上にbefore系コールバックでbuildするため、これだと変更処理がうまくいかない
      self.user_id = deal.user_id
      self.date = deal.date
      self.daily_seq = deal.daily_seq
      self.confirmed = deal.confirmed
    end
    raise "no user_id" unless self.user_id
    raise "no date" unless self.date
    raise "no daily_seq" unless self.daily_seq
  end

  def contents_updated?
    stored = Entry::Base.find(self.id)

    # 金額/残高が変更されていたら中身が変わったとみなす
    stored.amount.to_i != self.amount.to_i || stored.balance.to_i != self.balance.to_i
  end

  def assert_no_settlement
    raise "#{self.inspect} は精算データ #{(self.settlement || self.result_settlement).inspect} に紐づいているため削除できません。さきに精算データを削除してください。" if self.settlement || self.result_settlement
  end

  # 更新の場合、位置を移動していれば、移動前の位置の直後の残高記入の含み損益にも影響があるので、影響のある残高記入を探しておく
  def set_next_balance_entry_before_move
    if date_changed? || daily_seq_changed?
      @next_balance_entry_before_move = Entry::Balance.of(account_id).after(Entry::Base.find(id)).ordered.includes(:deal).first
    end
  end

  # 直後の残高記入のamountを再計算する
  def update_balance
    next_balance_entry = Entry::Balance.of(account_id).after(self).ordered.includes(:deal).first

    # 影響を受けた残高は、前から処理しないと、後ろの残高が正しく計算されない
    balance_entries = [next_balance_entry, @next_balance_entry_before_move].compact.uniq.sort do |a, b|
      if a.date != b.date
        a.date <=> b.date
      else
        a.daily_seq <=> b.daily_seq
      end
    end

    balance_entries.each do |e|
      e.deal.update_amount
    end
  end

end
