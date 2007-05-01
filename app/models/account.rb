class Account < ActiveRecord::Base
  include TermHelper
  has_one :account_rule,
          :dependent => true
  has_many :associated_account_rules,
           :class_name => 'AccountRule',
           :foreign_key => 'associated_account_id'
  belongs_to :user

  has_and_belongs_to_many :connected_accounts,
                          :class_name => 'Account',
                          :join_table => 'account_links',
                          :foreign_key => 'connected_account_id',
                          :association_foreign_key => 'account_id'

  has_and_belongs_to_many :associated_accounts,
                          :class_name => 'Account',
                          :join_table => 'account_links',
                          :foreign_key => 'account_id',
                          :association_foreign_key => 'connected_account_id'

  belongs_to              :partner_account,
                          :class_name => 'Account',
                          :foreign_key => 'partner_account_id'
  
  attr_accessor :balance, :percentage
  attr_reader :name_with_asset_type
  validates_presence_of :name,
                        :message => "名前を定義してください。"
  validates_presence_of :account_type_code
  validates_uniqueness_of :name, :scope => 'user_id', :message => "口座・費目・収入内訳で名前が重複しています。"
  
  # TODO: 口座種別、資産種別見直し中。Model中では Symbol で持つようにして文字列でDBに格納。Symbol → 名前はここで面倒を見るが基本的にメソッドで変換する。ビジネスモードで呼び方を変える。
  
  # 口座種別値
  ACCOUNT_ASSET = 1
  ACCOUNT_EXPENSE = 2
  ACCOUNT_INCOME = 3
  
  # 資産種別値
  ASSET_CACHE = 1
  ASSET_BANKING_FACILITY = 2
  ASSET_CREDIT_CARD = 3
  ASSET_CREDIT = 4
  ASSET_CAPITAL_FUND = 5

  # TODO: わかりにくいので何とかしたい

  @@account_types = {ACCOUNT_ASSET => '口座', ACCOUNT_EXPENSE => '支出', ACCOUNT_INCOME => '収入'}
  
  @@asset_types = {ASSET_CACHE => '現金', ASSET_BANKING_FACILITY => '金融機関口座', ASSET_CREDIT_CARD => 'クレジットカード', ASSET_CREDIT => '債権', ASSET_CAPITAL_FUND => '資本金'}

  @@connectable_type = {ACCOUNT_ASSET => ACCOUNT_ASSET, ACCOUNT_EXPENSE => ACCOUNT_INCOME, ACCOUNT_INCOME => ACCOUNT_EXPENSE}

  ASSET_TYPES = [
    [@@asset_types[ASSET_CACHE], ASSET_CACHE],
    [@@asset_types[ASSET_BANKING_FACILITY], ASSET_BANKING_FACILITY],
    [@@asset_types[ASSET_CREDIT_CARD], ASSET_CREDIT_CARD],
    [@@asset_types[ASSET_CREDIT], ASSET_CREDIT],
    [@@asset_types[ASSET_CAPITAL_FUND], ASSET_CAPITAL_FUND]
  ]
  RULE_APPLICABLE_ASSET_TYPES = [
    ASSET_TYPES[2],
    ASSET_TYPES[3],
  ]
  RULE_ASSOCIATED_ASSET_TYPES = [
    ASSET_TYPES[1]
  ]
  
  ACCOUNT_TYPE_SYMBOL = [:asset, :expense, :income]
  ACCOUNT_TYPE_ATTRIBUTES = {
    :asset =>   {:code => 1, :name => '口座',    :short_name => '口座'},
    :expense => {:code => 2, :name => '費目',    :short_name => '支出'},
    :income =>  {:code => 3, :name => '収入内訳', :short_name => '収入'}
  }
  ASSET_TYPE_SYMBOL = [:cache, :banking_facility, :credit_card, :credit, :capital_fund]
  ASSET_TYPE_ATTRIBUTES = {
    :cache            =>   {:code => 1, :name => '現金'},
    :banking_facility =>   {:code => 2, :name => '金融機関口座'},
    :credit_card      =>   {:code => 3, :name => 'クレジットカード'},
    :credit           =>   {:code => 4, :name => '債権'},
    :capital_fund     =>   {:code => 5, :name => '資本金', :business_only => true}
  }
  
  def self.account_type
    ACCOUNT_TYPE_ATTRIBUTES
  end
  
  def account_type_symbol # _symbol はリファクタリング終了後に名前変更予定
    raise "#{self.id} #{self.name}には account_type_code がありません" unless self.account_type_code
    ACCOUNT_TYPE_SYMBOL[self.account_type_code-1]
  end
  
  def account_type_symbol=(symbol)
    pos = ACCOUNT_TYPE_SYMBOL.index(symbol)
    raise "unknown account type symbol #{symbol}" unless pos
    self.account_type_code = pos + 1
    self.asset_type_code = nil if symbol != :asset
  end
  
  def asset_type_symbol
    return nil if !self.asset_type_code || self.asset_type_code <= 0
    ASSET_TYPE_SYMBOL[self.asset_type_code-1]
  end
  
  def asset_type_symbol=(symbol)
    self.asset_type_code = ASSET_TYPE_SYMBOL.index(symbol) + 1
  end
  
  # リファクタリングのため用意
  def account_type
    self.account_type_code
  end

  def asset_type
    self.asset_type_code
  end
  
  # 連携設定 ------------------

  def connect(target_user_login_id, target_account_name, interactive = true)
    friend_user = User.find_friend_of(self.user_id, target_user_login_id)
    raise "no friend user" unless friend_user

    connected_account = Account.get_by_name(friend_user.id, target_account_name)
    raise "フレンド #{partner_user.login_id} さんには #{target_account_name} がありません。" unless connected_account

    raise "すでに連動設定されています。" if connected_accounts.detect {|e| e.id == connected_account.id} 
    
    raise "#{@@account_types[account_type]} には #{@@account_types[connected_account.account_type]} を連動できません。#{@@account_types[@@connectable_type[account_type]]} だけを連動することができます。" unless connected_account.account_type_code == @@connectable_type[account_type]
    connected_accounts << connected_account
    # interactive なら逆リンクもはる。すでにあったら黙ってパスする
    associated_accounts << connected_account if interactive && !associated_accounts.detect {|e| e.id == connected_account.id}
    save!
  end

  def clear_connection(connected_account)
    connected_accounts.delete(connected_account)
  end

  def connected_or_associated_accounts_size
    size = connected_accounts.size
    for account in associated_accounts
      size += 1 unless connected_accounts.detect{|e| e.id == account.id}
    end
    return size
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
        :conditions => ["user_id = ? and name = ? and account_type_code = ? and asset_type_code = ?", user_id, name, Account::ACCOUNT_ASSET, Account::ASSET_CREDIT]
     )
  end
  
  def self.find_default_asset(user_id)
    return Account.find(
      :first,
      :conditions => ["user_id = ? and account_type_code = ?", user_id, Account::ACCOUNT_ASSET],
      :order => "sort_key"
    )
  end

  def self.count_in_user(user_id, account_types = nil)
    if account_types
      return count(:conditions => ["user_id = ? and account_type_code in (?)", user_id, account_types.join(',')])
    else
      return count(:conditions => ["user_id = ?", user_id])
    end
  end

  # 表示系 （エラーにも登場するので model に持たせる）---------------------
  
  # 資産なら資産口座種類、それ以外なら短い口座種類名を返す。
  def type_shortname
    asset_type_name||account_type_shortname
  end
  
  # 資産口座種類名を返す。資産口座でなければnilを返す。
  def asset_type_name
    begin
      return ASSET_TYPE_ATTRIBUTES[asset_type_symbol][:name]
    rescue
      return nil
    end
  end

  # 勘定名（勘定種類 or 資産種類)
  def name_with_asset_type
    "#{self.name}(#{type_shortname})"
  end

  # with_asset_type の前にユーザー名をつけたもの
  def name_with_user
    return "#{user.login_id} さんの #{name_with_asset_type}"
  end

  def self.account_types
    @@account_types
  end

  def account_type_name
    ACCOUNT_TYPE_ATTRIBUTES[account_type_symbol][:name]
  end
  
  def account_type_shortname
    ACCOUNT_TYPE_ATTRIBUTES[account_type_symbol][:short_name]
  end
  
  # rule の親になっていない account (credit系) を探す
  def self.find_rule_free(user_id)
    # rule に紐づいた account_id のリストを得る
    binded_accounts = AccountRule.find_by_sql("select account_id from account_rules where account_id is not null")
    binded_account_ids = []
    binded_accounts.each do |e|
      binded_account_ids << e["account_id"]
    end
    not_in_binded_accounts = binded_account_ids.empty? ? "" : " and id not in(#{binded_account_ids.join(',')})"
    
    find(:all,
     :conditions => ["user_id = ? and account_type_code = ? and asset_type_code in (?, ?)#{not_in_binded_accounts}",
        user_id,
        ACCOUNT_ASSET,
        ASSET_CREDIT_CARD,
        ASSET_CREDIT],
     :order => 'sort_key')
  end

  # 口座別計算メソッド
  
  # 指定された日付より前の時点での残高を計算して balance に格納する
  # TODO: 格納したくない。返り値の利用でいい人はそうして。
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
      options = RULE_APPLICABLE_ASSET_TYPES
    elsif !associated_account_rules.empty?
      options = RULE_ASSOCIATED_ASSET_TYPES
    else
      options = ASSET_TYPES
    end
    # TODO: とてもわかりにくいのでなんとかしたい
    user.preferences.business_use? ? options : options.reject{|v| v[0] == @@asset_types[ASSET_CAPITAL_FUND]}
  end
  
  # 口座の初期設定を行う
  def self.create_default_accounts(user_id)
    # 口座
    create_accounts(user_id, ACCOUNT_ASSET, ['現金'], 1, ASSET_CACHE)
    # 支出
    create_accounts(user_id, ACCOUNT_EXPENSE, ['食費','住居・備品','水・光熱費','被服・美容費','医療費','理容衛生費','交際費','交通費','通信費','教養費','娯楽費','税金','保険料','雑費','予備費','教育費','自動車関連費'])
    # 収入
    create_accounts(user_id, ACCOUNT_INCOME, ['給料', '賞与', '利子・配当', '贈与'] )
  end
  
  protected
  def self.create_accounts(user_id, account_type, names, sort_key_start = 1, asset_type = nil)
    sort_key = sort_key_start
    for name in names
      create(:user_id => user_id, :name => name, :account_type_code => account_type, :asset_type_code => asset_type, :sort_key => sort_key)
      sort_key += 1
    end
  end
  
  def validate
    # asset_type が金融機関でないのに、精算口座として使われていてはいけない。
    if ACCOUNT_ASSET == account_type && ASSET_BANKING_FACILITY != asset_type
      errors.add(:asset_type_code, "精算口座として精算ルールで使用されています。") unless AccountRule.find_associated_with(id).empty?
    end
    # asset_type が債権でもクレジットカードでもないのに、精算ルールを持っていてはいけない。
    if ACCOUNT_ASSET == account_type && ASSET_CREDIT_CARD != asset_type && ASSET_CREDIT != asset_type
      errors.add(:asset_type_code, "精算ルールが適用されています。") unless AccountRule.find_binded_with(id).empty?
    end
    # 連動設定のチェックは有効だがバリデーションエラーでもなぜかリンクは張られてしまうため連動追加メソッド側でチェック
    # 受け皿口座が同じユーザーであることをチェック  TODO: ＵＩで制限しているため、単体テストにて確認したい
    if partner_account
      errors.add(:partner_account_id, "同じユーザーの口座しか受け皿口座に設定できません。") unless partner_account.user_id == self.user_id
    end
  end
  
  def before_destroy
    # 使われていたら消せない
    raise "#{account_type_name} '#{target_account.name}' はすでに使われているため削除できません。" if AccountEntry.find(:first, :conditions => "account_id = #{self.id}")
    # 精算口座として使われていたら削除できない
    raise "「#{name}」は精算口座として使われているため削除できません。" unless associated_account_rules.empty?

  end
    
end
