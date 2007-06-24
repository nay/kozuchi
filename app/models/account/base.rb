class Account::Base < ActiveRecord::Base
  set_table_name "accounts"

  # ---------- 口座種別の静的属性を設定するためのメソッド群
  
  def self.to_sym
    self.name.demodulize.underscore.to_sym
  end
  
  def self.sym_to_class(sym)
    eval "Account::#{sym.to_s.camelize}"
  end
  
  def type_in?(type)
    t = self.class.sym_to_class(type) unless type.kind_of?(Class)
    self.kind_of? t
  end

  # すぐ下の派生クラスの配列を返す。Base は口座種別、Assetは資産種別となる
  def self.types
    @types ||= []
    return @types.clone
  end

  # 継承されたときは口座種類配列を更新する
  def self.inherited(subclass)
    @types ||= []
    @types << subclass unless @types.include?(subclass)
    super
  end
  
  def self.type_order(order = nil)
    @type_order ||= 0
    return @type_order unless order
    @type_order = order
  end
  
  # 口座種類配列をソートする
  def self.sort_types
    @types ||= []
    @types.sort!{|a, b| a.type_order <=> b.type_order}
  end
  
  def self.type_name(name = nil)
    return @type_name unless name
    @type_name = name
  end
  
  def self.short_name(short_name = nil)
    return @short_name unless short_name
    @short_name = short_name
  end
  
  def self.connectable_type(clazz = nil)
    return @connectable_type unless clazz
    @connectable_type = clazz
  end

  # 勘定名（勘定種類 or 資産種類)
#  def self.name_with_asset_type
#    "#{self.type_name}(#{self.kind_of?(Asset) ? self.asset_name : self.short_name})"
#  end
  
  # TODO: リファクタリングしたい
  def name_with_asset_type
    "#{self.name}(#{self.kind_of?(Asset) ? self.class.asset_name : self.class.short_name})"
  end

  # TODO: 呼び出し側のリファクタリング確認
  # 資産口座種類名を返す。資産口座でなければnilを返す。
  def asset_type_name
    self.class.kind_of?(Asset) ? self.class.asset_name : nil
  end

  # TODO: 呼び出し側のリファクタリング確認
  # with_asset_type の前にユーザー名をつけたもの
  def name_with_user
    return "#{user.login_id} さんの #{name_with_asset_type}"
  end
  
  # ---------- 機能

  include TermHelper
  belongs_to :user

  has_and_belongs_to_many :connected_accounts,
                          :class_name => 'Account::Base',
                          :join_table => 'account_links',
                          :foreign_key => 'connected_account_id',
                          :association_foreign_key => 'account_id'

  has_and_belongs_to_many :associated_accounts,
                          :class_name => 'Account::Base',
                          :join_table => 'account_links',
                          :foreign_key => 'account_id',
                          :association_foreign_key => 'connected_account_id'

  belongs_to              :partner_account,
                          :class_name => 'Account::Base',
                          :foreign_key => 'partner_account_id'
  
  attr_accessor :balance, :percentage
  validates_presence_of :name,
                        :message => "名前を定義してください。"
  validates_uniqueness_of :name, :scope => 'user_id', :message => "#{Account::Base.types.map{|type| type.type_name}.join('・')}で名前が重複しています。"
  validate :validates_partner_account
  before_destroy :assert_not_used
  
#  # TODO: 口座種別、資産種別見直し中。Model中では Symbol で持つようにして文字列でDBに格納。Symbol → 名前はここで面倒を見るが基本的にメソッドで変換する。ビジネスモードで呼び方を変える。
#  
#  # 口座種別値
#  ACCOUNT_ASSET = 1
#  ACCOUNT_EXPENSE = 2
#  ACCOUNT_INCOME = 3
#  
#  # 資産種別値
#  ASSET_CACHE = 1
#  ASSET_BANKING_FACILITY = 2
#  ASSET_CREDIT_CARD = 3
#  ASSET_CREDIT = 4
#  ASSET_CAPITAL_FUND = 5
#
#  # TODO: わかりにくいので何とかしたい
#
#  @@asset_types = {ASSET_CACHE => '現金', ASSET_BANKING_FACILITY => '金融機関口座', ASSET_CREDIT_CARD => 'クレジットカード', ASSET_CREDIT => '債権', ASSET_CAPITAL_FUND => '資本金'}
#
#  ASSET_TYPES = [
#    [@@asset_types[ASSET_CACHE], ASSET_CACHE],
#    [@@asset_types[ASSET_BANKING_FACILITY], ASSET_BANKING_FACILITY],
#    [@@asset_types[ASSET_CREDIT_CARD], ASSET_CREDIT_CARD],
#    [@@asset_types[ASSET_CREDIT], ASSET_CREDIT],
#    [@@asset_types[ASSET_CAPITAL_FUND], ASSET_CAPITAL_FUND]
#  ]
#  #TODO: なくしたい
#  RULE_APPLICABLE_ASSET_TYPES = [
#    ASSET_TYPES[2],
#    ASSET_TYPES[3],
#  ]
#  RULE_ASSOCIATED_ASSET_TYPES = [
#    ASSET_TYPES[1]
#  ]
#  
#  ACCOUNT_TYPE_SYMBOL = [:asset, :expense, :income]
#  ACCOUNT_TYPE_ATTRIBUTES = {
#    :asset =>   {:code => 1, :name => '口座',    :short_name => '口座',  :connectable => :asset},
#    :expense => {:code => 2, :name => '費目',    :short_name => '支出',  :connectable => :income},
#    :income =>  {:code => 3, :name => '収入内訳', :short_name => '収入',  :connectable => :expense}
#  }
#  ASSET_TYPE_SYMBOL = [:cache, :banking_facility, :credit_card, :credit, :capital_fund]
#  ASSET_TYPE_ATTRIBUTES = {
#    :cache            =>   {:code => 1, :name => '現金'},
#    :banking_facility =>   {:code => 2, :name => '金融機関口座', :rule_applicable => true},
#    :credit_card      =>   {:code => 3, :name => 'クレジットカード', :rule_applicable => true},
#    :credit           =>   {:code => 4, :name => '債権'},
#    :capital_fund     =>   {:code => 5, :name => '資本金', :business_only => true}
#  }
#  
#  def self.account_type
#    ACCOUNT_TYPE_ATTRIBUTES
#  end
#  
#  def self.asset_type
#    ASSET_TYPE_ATTRIBUTES
#  end
#  
#  def account_type_connectable
#    ACCOUNT_TYPE_ATTRIBUTES[self.account_type_symbol][:connectable]
#  end
#  
#  def account_type_symbol # _symbol はリファクタリング終了後に名前変更予定
#    raise "#{self.id} #{self.name}には account_type_code がありません" unless self.account_type_code
#    ACCOUNT_TYPE_SYMBOL[self.account_type_code-1]
#  end
#  
#  def account_type_symbol=(symbol)
#    pos = ACCOUNT_TYPE_SYMBOL.index(symbol)
#    raise "unknown account type symbol #{symbol}" unless pos
#    self.account_type_code = pos + 1
#    self.asset_type_code = nil if symbol != :asset
#  end
#  
#  def asset_type_symbol
#    return nil if !self.asset_type_code || self.asset_type_code <= 0
#    ASSET_TYPE_SYMBOL[self.asset_type_code-1]
#  end
#  
#  def asset_type_symbol=(symbol)
#    self.asset_type_code = ASSET_TYPE_SYMBOL.index(symbol) + 1
#  end
#  
#  # リファクタリングのため用意
#  def account_type
#    self.account_type_code
#  end
#
#  def asset_type
#    self.asset_type_code
#  end
  
  # 連携設定 ------------------

  def connect(target_user_login_id, target_account_name, interactive = true)
    friend_user = User.find_friend_of(self.user_id, target_user_login_id)
    raise "no friend user" unless friend_user

    connected_account = Account::Base.get_by_name(friend_user.id, target_account_name)
    raise "フレンド #{partner_user.login_id} さんには #{target_account_name} がありません。" unless connected_account

    raise "すでに連動設定されています。" if connected_accounts.detect {|e| e.id == connected_account.id} 
    
    raise "#{account_type_name} には #{connected_account.account_type_name} を連動できません。" unless self.kind_of?(connected_account.class.connectable_type)
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
    return Account::Base.find(:first, :conditions => ["user_id = ? and id = ?", user_id, account_id])
  end
  
  def self.get_by_name(user_id, name)
    return Account::Base.find(:first, :conditions => ["user_id = ? and name = ?", user_id, name])
  end

# 　使われてない？  
#  def self.find_credit(user_id, name)
#      return Account.find(
#        :first,
#        :conditions => ["user_id = ? and name = ? and account_type_code = ? and asset_type_code = ?", user_id, name, Account::ACCOUNT_ASSET, Account::ASSET_CREDIT]
#     )
#  end
  
  # TODO: user へ移動したい
#  def self.find_default_asset(user_id)
#    raise "no asset types" if Asset.types.empty?
#    find(
#      :first,
#      :conditions => ["user_id = ? and type in (#{Account::Asset.types.map{|t| '\'' + t.to_s.demodulize + '\''}.join(',')})", user_id],
#      :order => "sort_key"
#    )
#  end

# 使われてない？
#  def self.count_in_user(user_id, account_types = nil)
#    if account_types
#      return Account::Base.count(:conditions => ["user_id = ? and account_type_code in (?)", user_id, account_types.join(',')])
#    else
#      return Account::Base.count(:conditions => ["user_id = ?", user_id])
#    end
#  end

  # 表示系 （エラーにも登場するので model に持たせる）---------------------
  
#  # 資産なら資産口座種類、それ以外なら短い口座種類名を返す。
#  def type_shortname
#    asset_type_name||account_type_shortname
#  end

#  def account_type_name
#    ACCOUNT_TYPE_ATTRIBUTES[account_type_symbol][:name]
#  end
#  
#  def account_type_shortname
#    ACCOUNT_TYPE_ATTRIBUTES[account_type_symbol][:short_name]
#  end
  

  # 口座別計算メソッド
  
  # 指定された日付より前の時点での残高を計算して balance に格納する
  # TODO: 格納したくない。返り値の利用でいい人はそうして。
  def balance_before(date)
    @balance = AccountEntry.balance_at_the_start_of(self.user_id, self.id, date)
  end

  # 口座の初期設定を行う
  def self.create_default_accounts(user_id)
    # 口座
    Cache.create_accounts(user_id, ['現金'])
    # 支出
    Expense.create_accounts(user_id, ['食費','住居・備品','水・光熱費','被服・美容費','医療費','理容衛生費','交際費','交通費','通信費','教養費','娯楽費','税金','保険料','雑費','予備費','教育費','自動車関連費'])
    # 収入
    Income.create_accounts(user_id, ['給料', '賞与', '利子・配当', '贈与'] )
  end
  
  protected
  def self.create_accounts(user_id, names, sort_key_start = 1)
    sort_key = sort_key_start
    for name in names
      self.create(:user_id => user_id, :name => name, :sort_key => sort_key)
      sort_key += 1
    end
  end

  def validates_partner_account
    # 連動設定のチェックは有効だがバリデーションエラーでもなぜかリンクは張られてしまうため連動追加メソッド側でチェック
    # 受け皿口座が同じユーザーであることをチェック  TODO: ＵＩで制限しているため、単体テストにて確認したい
    if partner_account
      errors.add(:partner_account_id, "同じユーザーの口座しか受け皿口座に設定できません。") unless partner_account.user_id == self.user_id
    end
  end
  
  def assert_not_used
    # 使われていたら消せない
    raise "#{account_type_name} '#{target_account.name}' はすでに使われているため削除できません。" if AccountEntry.find(:first, :conditions => "account_id = #{self.id}")
  end

end

# require ではrails的に必要な文脈で確実にリロードされないので参照する
for d in Dir.glob(File.expand_path(File.dirname(__FILE__)) + '/*')
  clazz = d.scan(/.*\/(account\/.*).rb$/).to_s.camelize
  eval clazz
end
#ObjectSpace.each_object(Class){|o| o}

Account::Base.sort_types
Account::Asset.sort_types