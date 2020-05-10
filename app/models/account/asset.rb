class Account::Asset < Account::Base

  BASIC_KINDS = {
    cache:            {name: '現金',           banking: true},
    banking_facility: {name: '金融機関口座',    banking: true},
    credit_card:      {name: 'クレジットカード', banking: true, credit: true},
    credit:           {name: '債権',                          credit: true}
  }

  type_order 1
  type_name '口座'
  short_name '口座'
  connectable_type Account::Asset

  scope :categorized_as, ->(*kinds) {
    raise "You must specify at least one kind for Account::Asset.categorized_as" if kinds.empty?
    where("accounts.asset_kind in (?)", kinds)
  }

  with_options foreign_key: "settlement_target_account_id", class_name: "Account::Asset" do |s|
    s.belongs_to :settlement_paid_from
    s.has_many   :settlement_paid_for, dependent: :nullify # 自分が消されたら、自分を精算口座にしているカードの精算口座をnilにする
  end

  # クレジットカード用 デフォルトの記入探索期間を返す
  def term_for_settlement_paid_on(monthly_date)
    end_month = monthly_date.beginning_of_month << settlement_closed_on_month
    end_date = [end_month + (settlement_closed_on_day - 1), end_month.end_of_month].min
    start_date = (end_date << 1) - settlement_term_margin

    [start_date, end_date]
  end

  def asset?
    true
  end

  def self.has_kind?
    true
  end

  # TODO: 翻訳を使う感じにしたい
  def human_asset_kind
    attributes = BASIC_KINDS[asset_kind.to_sym]
    attributes ? attributes[:name] : nil
  end

  def capital_fund?
    asset_kind == "capital_fund"
  end

  def credit_card?
    asset_kind == "credit_card"
  end

  # 精算可能なクレジット系勘定かの判定
  def any_credit?
    credit_asset_kinds = asset_kinds{|attributes| attributes[:credit]}.map{|k| k.to_s}
    credit_asset_kinds.include?(asset_kind)
  end

  # TODO: Rails 2.2
  def self.human_name
    '口座'
  end

  # TODO: クラスベースがちょっと大変過ぎる＆別アプリケーション化にとって厳しいので揺り戻し
  def base_type
    :asset
  end
  def linkable_to?(target_base_type)
    target_base_type == :asset
  end
  

  def name_with_asset_type
    "#{self.name}(#{ASSET_KINDS[self.asset_kind.to_sym][:name]})"
  end

  # 期間内の不明金合計（ーなら支出）を得る。
  # 最初の残高記入に伴うamountは不明金扱いしない。
  def unknown_flow(start_date, end_date)
    balances.without_initial.date_from(start_date).before(end_date).sum(:amount)

#    entries.sum(:amount,
#      :joins => "inner join deals on account_entries.deal_id = deals.id",
#      :conditions => ["deals.type = 'Balance' and confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance = ?", true, start_date, end_date, false]) || 0
  end

  # ---------- 口座種別の静的属性を設定するためのメソッド群
#  def self.types
#    [Account::Cache, Account::BankingFacility, Account::CreditCard, Account::Credit, Account::CapitalFund]
#  end
  
#  def self.type_name(name = nil)
#    return Account::Asset.type_name if self != Account::Asset
#    super
#  end

  def self.short_name(short_name = nil)
    return Account::Asset.short_name if self != Account::Asset
    super
  end
  
  def self.connectable_type(clazz = nil)
    return Account::Asset.connectable_type if self != Account::Asset
    super
  end

  # ---------- 機能

  validate :validates_partner_account

  def self.create_accounts(user_id, asset_kind, names, sort_key_start = 1)
    sort_key = sort_key_start
    for name in names
      self.create(:user_id => user_id, :name => name, :asset_kind => asset_kind.to_s, :sort_key => sort_key)
      sort_key += 1
    end
  end

  private
  def serialized_attributes
    super.merge({:type => self.asset_kind})
  end

end

class Account::RuleAssociatedAccountException < Exception
  def initialize(account_name)
    super self.class.new_message(account_name)
  end
  def self.new_message(account_name)
    "「#{account_name}」は精算口座として使われているため削除できません。"
  end
end
