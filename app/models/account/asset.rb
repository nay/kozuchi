class Account::Asset < Account::Base
  type_order 1
  type_name '口座'
  short_name '口座'
  connectable_type Account::Asset

  # TODO: クラスベースがちょっと大変過ぎる＆別アプリケーション化にとって厳しいので揺り戻し
  def base_type
    :asset
  end
  def linkable_to?(target_base_type)
    target_base_type == :asset
  end
  

  def name_with_asset_type
    "#{self.name}(#{self.class.asset_name})"
  end

  # 期間内の不明金合計（ーなら支出）を得る。
  # 最初の残高記入に伴うamountは不明金扱いしない。
  def unknown_flow(start_date, end_date)
    entries.sum(:amount,
      :joins => "inner join deals on account_entries.deal_id = deals.id",
      :conditions => ["deals.type = 'Balance' and confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance = ?", true, start_date, end_date, false]) || 0
  end

  # ---------- 口座種別の静的属性を設定するためのメソッド群
  def self.types
    [Account::Cache, Account::BankingFacility, Account::CreditCard, Account::Credit, Account::CapitalFund]
  end
  
  def self.type_name(name = nil)
    return Account::Asset.type_name if self != Account::Asset
    super
  end

  def self.short_name(short_name = nil)
    return Account::Asset.short_name if self != Account::Asset
    super
  end
  
  def self.connectable_type(clazz = nil)
    return Account::Asset.connectable_type if self != Account::Asset
    super
  end

  def self.asset_name(asset_name = nil)
    return @asset_name unless asset_name
    @asset_name = asset_name
  end
  
  # 口座種類名からクラスを得る。
  # asset_name:: 口座種類名
  def self.asset_name_to_class(asset_name)
    types.detect{|a| a.asset_name == asset_name}  
  end
  
  def self.rule_applicable(flag)
    @rule_applicable = flag
  end
  def self.rule_applicable?
    !@rule_applicable.nil?
  end
  
  def self.rule_associatable(flag)
    @rule_associatable = flag
  end
  def self.rule_associatable?
    !@rule_associatable.nil?
  end

  def self.business_only(flag)
    @business_only = flag
  end
  def self.business_only?
    !@business_only.nil?
  end

  # ---------- 機能

  has_one :account_rule,
          :dependent => :destroy,
          :foreign_key => 'account_id'
  has_many :associated_account_rules,
           :class_name => 'AccountRule',
           :foreign_key => 'associated_account_id'

  validate :validates_partner_account, :validates_rule_associated, :validates_rule_applicable
  before_destroy :assert_rule_not_associated


  # rule の親になっていない account (credit系) を探す
  def self.find_rule_free(user_id)
    rule_applicable_types = Account::Asset.types.select{|t| t.rule_applicable? } # TODO: User クラスにもっていく
    assets = User.find(user_id).accounts.types_in(rule_applicable_types.map{|t| t.to_sym}) # TODO: class でも受け入れてもらえるようにする
    assets.select{|a| a.associated_account_rules.empty? }
  
    # rule に紐づいた account_id のリストを得る
#    binded_accounts = AccountRule.find_by_sql("select account_id from account_rules where account_id is not null")
#    binded_account_ids = []
#    binded_accounts.each do |e|
#      binded_account_ids << e["account_id"]
#    end
#    not_in_binded_accounts = binded_account_ids.empty? ? "" : " and id not in(#{binded_account_ids.join(',')})"
#    
#    find(:all,
#     :conditions => ["user_id = ? and account_type_code = ? and asset_type_code in (?, ?)#{not_in_binded_accounts}",
#        user_id,
#        account_type[:asset][:code],
#        asset_type[:credit_card][:code],
#        asset_type[:credit][:code]],
#     :order => 'sort_key')
  end

  # 削除可能性を調べる
  def deletable?
    super_deletable = super
    begin
      assert_rule_not_associated(false)
      return super_deletable
    rescue Account::RuleAssociatedAccountException => err
      delete_errors << err.message
      return false
    end
  end


  # account_type, asset_type, account_rule の整合性をあわせる
  def before_save
    # asset_type が credit 系でなければ、自分が適用対象として紐づいている rule があれば削除
    unless self.class.rule_applicable?
      self.account_rule = nil
    end
  end

  # 変更可能な口座種別を配列で返す。
  def changable_asset_types
    asset_types = Account::Asset.types
    asset_types.delete_if{|t| !t.rule_applicable? } if self.account_rule
    asset_types.delete_if{|t| !t.rule_associatable? } unless associated_account_rules.empty?
    asset_types.delete_if{|t| t.business_only? } unless user.preferences(true).business_use?
    asset_types
  end

  # 変更可能な口座種別を名前・名前の配列の配列で返す。
  def asset_type_options
    changable_asset_types.map{|t| [t.asset_name, t.asset_name]}
  end
  
  def asset_name
    self.class.asset_name
  end

  protected
  # asset_type が金融機関でないのに、精算口座として使われていてはいけない。
  def validates_rule_associated
    # TODO: 属性化したい
    unless self.kind_of? Account::BankingFacility
      errors.add(:type, "精算口座として精算ルールで使用されています。") unless AccountRule.find_associated_with(id).empty?
    end
  end
  # asset_type が債権でもクレジットカードでもないのに、精算ルールを持っていてはいけない。
  def validates_rule_applicable
    unless self.class.rule_applicable?
      errors.add(:asset_type_code, "精算ルールが適用されています。") unless AccountRule.find_binded_with(id).empty?
    end
  end
  # 精算口座として使われていたら例外を出す。
  # force:: true ならその時点でデータベースを新たに調べる。false ならキャッシュを使う。
  def assert_rule_not_associated(force = true)
    # 精算口座として使われていたら削除できない
    raise Account::RuleAssociatedAccountException.new(name) unless associated_account_rules(force).empty?
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

class Account::IllegalClassChangeException < Exception
  def self.new_message(account_name, illegal_asset_type_name)
    "「#{account_name}」を#{illegal_asset_type_name}に変更することはできません。"
  end
  def initialize(account_name, illegal_asset_type_name)
    super self.class.new_message(account_name, illegal_asset_type_name)
  end
end
