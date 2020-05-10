#TODO: UserProxy対応
class Settlement < ApplicationRecord
  belongs_to :account, :class_name => 'Account::Base', :foreign_key => 'account_id'

  has_many :target_entries,
           -> { order('deals.date, deals.daily_seq').includes(:deal) },
           class_name: 'Entry::General',
           foreign_key: 'settlement_id'

  # TODO: Rails 3.2.6 nullify時のSQLでORDERがあるのにjoinされない問題の回避のため
  has_many :nullify_target_entries,
           :class_name => 'Entry::General',
           :foreign_key => 'settlement_id',
           :dependent => :nullify

  has_one  :result_entry,
           -> { includes(:deal) },
           class_name: 'Entry::General',
           foreign_key: 'result_settlement_id'

  belongs_to :submitted_settlement
  
  belongs_to :user

  attr_accessor :result_date, :result_partner_account_id
  attr_reader :deal_ids

  before_validation :set_target_entries, :on => :create
  validate :validate_target_entries

  after_save :create_result_deal
  before_destroy :check_submitted
  after_destroy :destroy_reuslt_deal

  # result_entryのひもづけにacocunt_entriesというテーブル名が使われる想定
  scope :on, ->(account) { where("account_entries.account_id = ?", account.id) }

  # 同上
  scope :recent, ->(limit) { order("account_entries.date desc").limit(limit) }

  def deal_ids=(ids)
    @deal_ids = ids
  end

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.settlement(:id => "settlement#{self.id}", :account => "account#{self.account_id}") do
      xml.name XMLUtil.escape(name)
      xml.description XMLUtil.escape(description)
    end
  end

  def to_csv
    ["settlement", id, account_id, "\"#{name}\"", "\"#{description}\""].join(',')
  end

  def target_sum
    sum = 0
    target_entries.each{|e| sum += e.amount}
    sum
  end

  # お金が返ってくるときはプラス、出ていくときはマイナスになる金額を result_entry をもとに提供する
  def amount
    result_entry.amount * -1
  end

  def year
    result_entry.date.year
  end

  def month
    result_entry.date.month
  end

  # 相手に提出済にする
  def submit
    # すでに提出済ならエラー
    raise "すでに#{submitted_settlement.user.login}さんに提出されています。" if self.submitted_settlement
    
    target_account = account.link.target_account # 1つであることを想定
    raise "#{account.name}には連携先がありません。" unless target_account

    submitted = nil
    Settlement.transaction do
      submitted = SubmittedSettlement.create!(:user_id => target_account.user_id, :account_id => target_account.id, :name => "#{account.name}の精算")
      # この精算にひもづいた entry に対応する entryを全部これにひもづける
      for e in target_entries
        # 本来あるはずのリンクがない（先方が故意に消したなど）場合は新しく作る
        e.ensure_linking(target_account.user)
        submitted.target_entries << e.linked_account_entry
      end
      # この精算の result_entry のひもづけ
      raise "異常なデータです。精算取引がありません。" unless self.result_entry
      result_entry.ensure_linking(target_account.user) unless result_entry.linked_account_entry
      submitted.result_entry = result_entry.linked_account_entry
      
      self.submitted_settlement_id = submitted.id
      self.save!
    end

    submitted
  end
  
  def deletable?
    self.submitted_settlement_id.blank?
  end
  
  # すべて確認済か調べる
  def all_confirmed?
    return false if target_entries.detect{|e| !e.deal.confirmed?}
    result_entry.deal.confirmed?
  end
  
  private

  def validate_target_entries
    errors.add(:base, "対象取引が１件もありません。") if target_entries.empty?
  end

  def destroy_reuslt_deal
    self.result_entry.deal.destroy if self.result_entry
  end


  def check_submitted
    # submit されていたら消せない
    raise "提出済の精算データは削除できません。" if self.submitted_settlement_id
  end


  def create_result_deal
    self.target_entries.each{|e| e.save!}
    unless result_entry
      raise "No result_partner_account_id in #{self.inspect}" unless result_partner_account_id
      raise "No result_date in #{self.inspect}" unless result_date
      amount = 0
      target_entries.each{|e| amount -= e.amount}
      # account への出し入れの逆の金額が来る
      # 精算取引の金額がマイナスなら、accountから引くということ
      if amount < 0
        minus_account_id = self.account_id
        plus_account_id = self.result_partner_account_id
      else
        plus_account_id = self.account_id
        minus_account_id = self.result_partner_account_id
      end
      result_deal = Deal::General.new(
        :debtor_entries_attributes => [{:account_id => plus_account_id, :amount => amount.abs}],
        :creditor_entries_attributes => [{:account_id => minus_account_id, :amount => amount.abs*-1}],
        :date => self.result_date,
        :summary => self.name,
        :summary_mode => 'unify',
        :confirmed => true # false にすると、相手方の操作によって消されてしまう。リスク低減のためtrueにする
      )
      result_deal.user_id = user_id # TODO: こうでないとだめなことを確認
      result_deal.save!
      self.result_entry = result_deal.entries.detect{|e| e.account_id.to_s == self.account_id.to_s}
    end
    self.result_entry.save!
  end

  def set_target_entries
    return if !deal_ids || !target_entries.empty?
    # 対象取引を追加していく
    # TODO: 未確定などまずいやつは追加を禁止したい
    for deal_id in deal_ids
      # 複数明細の場合などに、２つ以上あることもあり得る
      entries = Entry::General.includes(:deal).references(:deal).where("deals.user_id = ? and deals.id = ? and account_id = ?", user_id, deal_id, account.id)
      next if entries.empty?
      entries.each do |entry|
        target_entries << entry
      end
    end
  end

end
