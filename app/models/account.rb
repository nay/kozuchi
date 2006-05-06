class Account < ActiveRecord::Base
  has_one :account_rule,
          :dependent => true
  has_many :associated_account_rules,
           :class_name => 'AccountRule',
           :foreign_key => 'associated_account_id'
  attr_accessor :account_type_name, :balance, :percentage
  attr_reader :name_with_asset_type
  validates_presence_of :name,
                        :message => "名前を定義してください。"
  validates_presence_of :account_type
  validates_uniqueness_of :name, :scope => 'user_id', :message => "口座・費目・収入内訳で名前が重複しています。"
  
  # 口座種別値
  ACCOUNT_ASSET = 1
  ACCOUNT_EXPENSE = 2
  ACCOUNT_INCOME = 3
  
  # 資産種別値
  ASSET_CACHE = 1
  ASSET_BANKING_FACILITY = 2
  ASSET_CREDIT_CARD = 3
  ASSET_CREDIT = 4
  
  @@asset_types = {ASSET_CACHE => '現金', ASSET_BANKING_FACILITY => '金融機関口座', ASSET_CREDIT_CARD => 'クレジットカード', ASSET_CREDIT => '債権'}

  ASSET_TYPES = [
    [@@asset_types[ASSET_CACHE], ASSET_CACHE],
    [@@asset_types[ASSET_BANKING_FACILITY], ASSET_BANKING_FACILITY],
    [@@asset_types[ASSET_CREDIT_CARD], ASSET_CREDIT_CARD],
    [@@asset_types[ASSET_CREDIT], ASSET_CREDIT]
  ]
  RULE_APPLICABLE_ASSET_TYPES = [
    ASSET_TYPES[2],
    ASSET_TYPES[3],
  ]
  RULE_ASSOCIATED_ASSET_TYPES = [
    ASSET_TYPES[1]
  ]

  def name_with_asset_type
    return "#{self.name}(#{@@asset_types[asset_type]||''})"
  end

  def self.asset_types
    @@asset_types
  end

  def self.get_account_type_name(account_type)
    account_type_names = {1 => "口座", 2 => "費目", 3 => "収入内訳"}
    account_type_names[account_type]
  end

  def account_type_name
    @account_type_name ||= Account.get_account_type_name(self.account_type)
  end
  
  # rule の親になっていない account (credit系) を探す
  def self.find_rule_free(user_id)
    # rule に紐づいた account_id のリストを得る
    binded_accounts = AccountRule.find_by_sql("select account_id from account_rules where account_id is not null")
    binded_account_ids = []
    binded_accounts.each do |e|
      binded_account_ids << e["account_id"]
    end
    find(:all,
     :conditions => ["user_id = ? and account_type = ? and asset_type in (?, ?) and id not in(#{binded_account_ids.join(',')})",
        user_id,
        ACCOUNT_ASSET,
        ASSET_CREDIT_CARD,
        ASSET_CREDIT],
     :order => 'sort_key')
  end
  
  def self.find_all(user_id, types, asset_types = nil)
    account_types = "";
    types.each do |type|
      if account_types != ""
        account_types += ","
      end
      account_types += type.to_s
    end
    conditions = "user_id = ? and account_type in (#{account_types})"
    if asset_types
      condition = "";
      asset_types.each do |t|
        if condition != ""
          condition += ","
        end
        condition += t.to_s
      end
      conditions += " and asset_type in (#{condition})"
    end
    Account.find(:all,
                 :conditions => [conditions, user_id],
                 :order => "sort_key")
  end

  # 口座別計算メソッド
  
  # 指定された日付より前の時点での残高を計算して balance に格納する
  def balance_before(date)
    @balance = AccountEntry.balance_at_the_start_of(self.user_id, self.id, date)
  end

  # account_type, asset_type, account_rule の整合性をあわせる
  def before_save
    # asset_type が credit 系でなければ、自分が適用対象として紐づいている rule があれば削除
    if self.asset_type != ASSET_CREDIT_CARD && self.asset_type != ASSET_CREDIT
      self.account_rule = nil
    end
  end
  
  # ルールとバインドできる口座種類か
  def rule_applicable
    return ACCOUNT_ASSET == account_type && (ASSET_CREDIT_CARD == asset_type || ASSET_CREDIT == asset_type)
  end
  
  def asset_type_options
    if self.account_rule
      return RULE_APPLICABLE_ASSET_TYPES
    end
    if !associated_account_rules.empty?
      return RULE_ASSOCIATED_ASSET_TYPES
    end
    
    return ASSET_TYPES
  end
  
  protected
  def validate
    # asset_type が金融機関でないのに、精算口座として使われていてはいけない。
    if ACCOUNT_ASSET == account_type && ASSET_BANKING_FACILITY != asset_type
      errors.add(:asset_type, "精算口座として精算ルールで使用されています。") unless AccountRule.find_associated_with(id).empty?
    end
    # asset_type が債権でもクレジットカードでもないのに、精算ルールを持っていてはいけない。
    if ACCOUNT_ASSET == account_type && ASSET_CREDIT_CARD != asset_type && ASSET_CREDIT != asset_type
      errors.add(:asset_type, "精算ルールが適用されています。") unless AccountRule.find_binded_with(id).empty?
    end
  end
  
  def before_destroy
    # 精算口座として使われていたら削除できない
    if !associated_account_rules.empty?
      raise "「#{name}」は精算口座として使われているため削除できません。"
    end
  end
    
end
