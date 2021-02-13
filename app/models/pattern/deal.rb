class Pattern::Deal < ApplicationRecord
  self.table_name = 'deal_patterns'

  belongs_to :user, :foreign_key => "user_id"
  with_options :class_name => "Pattern::Entry", :foreign_key => 'deal_pattern_id', :extend =>  ::Deal::EntriesAssociationExtension do |e|
    e.has_many :debtor_entries, -> { where(creditor: false).order(:line_number) },
               dependent: :destroy
    e.has_many :creditor_entries, -> { where(creditor: true).order(:line_number) },
               dependent: :destroy
  end
  include ::Deal
  # 読み出し専用の共通的なentry
  has_many :readonly_entries, -> { includes(:account).order(:line_number, :creditor).readonly },
           class_name: "Pattern::Entry",
           foreign_key: 'deal_pattern_id'

  attr_accessor :overwrites_code
#  attr_accessible :code, :name, :summary_mode, :summary, :debtor_entries_attributes, :creditor_entries_attributes, :overwrites_code

  before_validation :set_user_id_to_entries, :avoid_empty_code
  # 検証なしの場合も保証したいため以下は before_save で重複して実行する
  before_save :set_user_id_to_entries, :avoid_empty_code
  validates :code, :uniqueness => {:scope => :user_id, :allow_nil => true, :if => lambda{|r| !r.overwrites_code?}}
  validate :validate_entry_exists
  after_save :set_used_at

  scope :recent, -> { order(used_at: :desc) }
  scope :contains, ->(keyword) { select("DISTINCT deal_patterns.*").joins("inner join entry_patterns on entry_patterns.deal_pattern_id = deal_patterns.id").where("deal_patterns.code LIKE ? OR deal_patterns.name LIKE ? OR entry_patterns.summary LIKE ?", "#{keyword}%", "#{keyword}%", "#{keyword}%") }

  scope :with_account, ->(account_id, debtor) {
    # entry_patterns との join はされている想定
    where("entry_patterns.account_id = ? and entry_patterns.creditor = ?", account_id, !debtor)
  }

  def to_s
    "#{"#{code} " if code.present?}#{name.present? ? name : "*#{summary}"}"
  end

  def name_for_human
    to_s
  end

  def caption
    to_s
  end

  # サジェッション等で使う識別子
  def css_class
    'deal_pattern'
  end

  def overwrites_code?
    overwrites_code.to_i == 1 || overwrites_code == true
  end

  def use
    self.class.where(id: id).update_all({:used_at => current_time_from_proper_timezone}) unless new_record?
  end

  def assignable_attributes
    HashWithIndifferentAccess.new(attributes).merge({
        # 検証時の見せ方に影響するため必要
        :summary_mode => summary_mode,
        :summary => @unified_summary,
        :debtor_entries_attributes => debtor_entries.map(&:assignable_attributes),
        :creditor_entries_attributes => creditor_entries.map(&:assignable_attributes)
      }).except(:id, :user_id, :created_at, :updated_at, :used_at)
  end

  def save(*)
    transaction do
      old_id = new_record? ? nil : id
      prepare_overwrite
      if (result = super) && old_id && old_id != id
        old = self.class.find_by(id: old_id)
        old.destroy if old
      end
      return result
    end
  end

  def save!(*)
    transaction do
      old_id = new_record? ? nil : id
      prepare_overwrite
      result = super
      if old_id && old_id != id
        old = self.class.find_by(id: old_id)
        old.destroy if old
      end
      return result
    end
  end

  # コードの上書きが指定されていた場合、上書きモードにする
  # id が更新された場合は true を返す
  def prepare_overwrite
    return false unless overwrites_code?
    return false if code.blank? # 強制でnil にする前に通ると思われるためblank?で判定する

    # 対応するcodeを持つ既存レコードを取得
    target = self.class.find_by(code: code)
    return false unless target # 対象が存在しなければ無視（通常の create or update）

    # 自分がそのレコードであればなにもしない（普通に更新する）
    return false if !new_record? && self.id == target.id

    # 内容を保存しておく
    copied_attributes = assignable_attributes

    # 対応するcodeを持つ既存レコードを表すオブジェクトに変換する（Rails依存）
    self.id = target.id
    @new_record = false
    reload

    # 変更内容を入れる
    self.attributes = copied_attributes
    # 上書きモードは解除する
    self.overwrites_code = nil

    true
  end


  private

  def set_used_at
    self.class.where(id: id).update_all({:used_at => updated_at})
  end

  def avoid_empty_code
    self.code = nil if code.blank?
  end

  def validate_entry_exists
    errors.add(:base, '記入内容がありません。') if debtor_entries.empty? && creditor_entries.empty?
  end

  def set_user_id_to_entries
    debtor_entries.each do |e|
      e.user_id ||= user_id
    end
    creditor_entries.each do |e|
      e.user_id ||= user_id
    end
  end

end
