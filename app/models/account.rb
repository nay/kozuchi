class Account < ActiveRecord::Base
  has_one :account_rule,
          :dependent => true
  has_many :associated_account_rules,
           :class_name => 'AccountRule',
           :foreign_key => 'associated_account_id'
  belongs_to :partner_applying_account,
             :class_name => 'Account',
             :foreign_key => 'partner_account_id'
  has_one    :partner_applied_account,
             :class_name => 'Account',
             :foreign_key => 'partner_account_id'
  belongs_to :user
  
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

  @@account_types = {ACCOUNT_ASSET => '口座', ACCOUNT_EXPENSE => '支出', ACCOUNT_INCOME => '収入'}
  
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

  def partner_account
    partner_account = self.partner_applying_account
    p "applying_account = #{self.partner_applying_account}"
    if partner_account
      p "applied_account = #{self.partner_applied_account}"
      if self.partner_applied_account && self.partner_applied_account.id == partner_account.id
        p "applying == applied"
        return partner_account if User.is_friend(self.user_id, partner_account.user_id)
      end
    end
    return nil
  end

  
  def self.get(user_id, account_id)
    return Account.find(:first, :conditions => ["user_id = ? and id = ?", user_id, account_id])
  end
  
  def self.get_by_name(user_id, name)
    return Account.find(:first, :conditions => ["user_id = ? and name = ?", user_id, name])
  end
  
  def self.find_credit(user_id, name)
      return Account.find(
        :first,
        :conditions => ["user_id = ? and name = ? and account_type = ? and asset_type = ?", user_id, name, Account::ACCOUNT_ASSET, Account::ASSET_CREDIT]
     )
  end
  
  def self.find_default_asset(user_id)
    return Account.find(
      :first,
      :conditions => ["user_id = ? and account_type = ?", user_id, Account::ACCOUNT_ASSET],
      :order => "sort_key"
    )
  end

  
#  def friend_user
#    if self.account_type == ACCOUNT_ASSET && self.asset_type == ASSET_CREDIT
#      return User.find_friend_of(self.user_id, self.name)
#    end
#    nil
#  end
  
  def self.count_in_user(user_id, account_types = nil)
    if account_types
      return count(:conditions => ["user_id = ? and account_type in (?)", user_id, account_types.join(',')])
    else
      return count(:conditions => ["user_id = ?", user_id])
    end
  end

  def name_with_asset_type
    return "#{self.name}(#{@@asset_types[asset_type]||@@account_types[account_type]})"
  end

  def self.account_types
    @@account_types
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
    p "before_save #{self.id}"
    # asset_type が credit 系でなければ、自分が適用対象として紐づいている rule があれば削除
    if self.asset_type != ASSET_CREDIT_CARD && self.asset_type != ASSET_CREDIT
      self.account_rule = nil
    end
  end
  
  def after_save
    # とにかくセーブは行う。
    # セーブした結果として、不整合が起きたら調整する
    if self.partner_account_id
    # 自分がpartner指定している以外の口座からpartner指定されていたら、指定されているリンクを解除する
      Account.update_all("partner_account_id = null", ["partner_account_id = ? and id != ?", self.id, self.partner_account_id])
      # 自分がpartner指定している口座から partner指定されていなかったら、空いていたら張る。空いていなければ例外
      if !self.partner_applying_account(true).partner_account_id
        partner_applying_account.partner_account_id = self.id
        partner_applying_account.save!
      else
        # 自分以外のものとリンクが張られていたら例外を発生させる
        raise "'#{self.partner_applying_account.user.login_id}'さんの'#{self.partner_applying_account.name}'はすでにほかの口座との連動が設定されています。" if self.partner_applying_account.partner_account_id != self.id
        # 自分と張られている場合はなにもしない
      end
    else
    # パートナー指定していなければ全部解除するだけ
      Account.update_all("partner_account_id = null", ["partner_account_id = ?", self.id])
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
