# ユーザーに紐づくロジックは多いので、機能別にモジュールを記述してincludeする
require 'digest/sha1'
class User < ActiveRecord::Base
  include User::Friend
  include User::Mobile

  delegate :uses_complex_deal?, :bookkeeping_style?, :to => :preferences

  has_many  :single_logins, :dependent => :destroy
  has_many  :settlements, :dependent => :destroy
  has_one   :preferences, :class_name => "Preferences", :dependent => :destroy
  has_many  :incomes, :class_name => 'Account::Income', :order => "sort_key"
  has_many  :expenses, :class_name => 'Account::Expense', :order => "sort_key"
  has_many  :assets, :class_name => "Account::Asset", :order => "sort_key"
  has_many  :flow_accounts, :class_name => "Account::Base", :conditions => "asset_kind is null", :order => "sort_key"
#  has_many  :accounts, :class_name => 'Account::Base', :include => [:link_requests, :link, :any_entry], :order => 'accounts.sort_key' do

  ACCOUNTS_OPTIONS_ASC = ['Account::Asset', 'Account::Income', 'Account::Expense']
  ACCOUNTS_OPTIONS_DESC = ['Account::Expense', 'Account::Asset', 'Account::Income']
  has_many  :accounts, :class_name => 'Account::Base', :order => 'accounts.sort_key' do

    def grouped_options(is_asc = true)
      grouped = group_by{|a| a.class}.map{|key, value| [key, value.map{|a| [a.name, a.id]}]}
      order = is_asc ? ACCOUNTS_OPTIONS_ASC : ACCOUNTS_OPTIONS_DESC
      grouped.sort!{|a, b|
        # 昇順／降順が対照的でないため独自ロジック
        order.index(a[0].name) <=> order.index(b[0].name)
      }
      grouped.map{|g| g[0] = g[0].human_name; g}
    end

    # 指定した日の最初における指定した口座の残高合計を得る
    def balance_sum(date, conditions = nil)
      with_joined_scope(conditions) do
        sum("account_entries.amount",
          :conditions => ["(deals.confirmed = ? and deals.date < ?) or account_entries.initial_balance = ?", true, date, true]
        ).to_i
      end
    end
    
    # 指定した日の最初における指定した口座の残高をAccountモデルの一覧として得る
    def balances(date, conditions = nil)
      with_joined_scope(conditions) do
        find(:all, :select => "accounts.*, sum(account_entries.amount) as balance",
          :include => nil,
          :conditions => ["(deals.confirmed = ? and deals.date < ?) or account_entries.initial_balance = ?", true, date, true],
          :group => 'accounts.id'
        ).each{|a| a.balance = a.balance.to_i}
      end
    end
    
    # 指定した期間における収入口座のフロー合計を得る。収入の不明金も含める。
    def income_sum(start_date, end_date)
      result = flow_sum(start_date, end_date, "accounts.type = 'Income'")
      unknowns(start_date, end_date).delete_if{|a| a.unknown >= 0}.each{|a| result += a.unknown}
      result
    end

    # 指定した期間における支出口座のフロー合計を得る。支出の不明金も含める。
    def expense_sum(start_date, end_date)
      result = flow_sum(start_date, end_date, "accounts.type = 'Expense'")
      unknowns(start_date, end_date).delete_if{|a| a.unknown <= 0}.each{|a| result += a.unknown}
      result
    end
    
    # 指定した期間における指定した口座のフロー合計を得る。不明金は扱わない。
    def flow_sum(start_date, end_date, conditions = nil)
      with_joined_scope(conditions) do
        sum("account_entries.amount",
          :conditions => ["deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true]
        ).to_i
      end
    end
    
    # 指定した期間における指定した口座のフローをAccountモデルの一覧として得る。flowカラムに格納される。
    # 資産口座の不明金を結果に足すことはしない。
    # 記入のない口座は取得されない。
    def flows(start_date, end_date, conditions = nil)
      with_joined_scope(conditions) do
        find(:all, :select => "accounts.*, sum(account_entries.amount) as flow",
          :include => nil,
          :conditions => ["deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true],
          :group => 'accounts.id'
        ).each{|a| a.flow = a.flow.to_i}
      end
    end

    # 指定した期間における指定した口座の不明金を Accountモデルの一覧として得る。不明金は unknown カラムに格納される。
    # 不明金勘定の視点から、正負は逆にする。つまり、支出の不明金はプラスで出る。
    def unknowns(start_date, end_date, conditions = nil)
      with_joined_scope(conditions) do
        find(:all, :select => "accounts.*, sum(account_entries.amount) as unknown",
          :include => nil,
          :conditions => ["deals.type = 'Balance' and deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true],
          :group => 'accounts.id'
        ).each{|a| a.unknown = a.unknown.to_i; a.unknown *= -1}
      end
    end
  
    # 指定した account_type のものだけを抽出する
    # TODO: 遅いので修正する
#    def types_in(*account_types)
#      account_types = account_types.flatten
#      self.select{|a| account_types.detect{|t| a.type_in?(t)} }
#    end
    
    private
    def with_joined_scope(conditions, &block)
      with_scope :find => {:conditions => conditions, :joins => "inner join account_entries on accounts.id = account_entries.account_id inner join deals on account_entries.deal_id = deals.id"} do
        yield
      end
    end
  end

#  # TODO: 関連に移行
#  def assets
#    accounts.types_in(:asset)
#  end

  # ProxyUser共通で使えるAccountオブジェクトを取得。この時点ではまだ通信は発生しない
  def account(account_id)
     accounts.find(account_id)

#    AccountProxy.new(account_id)
  end

  # ProxyUser共通で使えるAccountオブジェクトを取得。この時点ではまだ通信は発生しない
  def account_by_name(account_name)
    accounts.find_by_name(account_name)

#    AccountProxy.new(account_id)
  end

  include User::AccountLinking
  
  has_many :deals, :class_name => 'Deal::Base', :extend => User::DealsExtension
  # 作成用
  has_many :general_deals, :class_name => "Deal::General", :foreign_key => "user_id"
  has_many :balance_deals, :class_name => "Deal::Balance", :foreign_key => "user_id"

  has_many :entries, :class_name => "Entry::Base"
  
  def default_asset
    assets.first
  end

  # TODO: 賢くしたい
  def default_asset_other_than(*excludes)
    assets.detect{|a| !excludes.include?(a)}
  end

  # all logic has been moved into login_engine/lib/login_engine/authenticated_user.rb
  def login_id
    self.login
  end
  

  def self.find_by_login_id(login_id)
    find(:first, :conditions => ["login = ? ", login_id])
  end
  
  def deal_exists?(date)
    Deal::Base.exists?(self.id, date)
  end
  

  def available_asset_kinds
    if preferences.business_use? && defined?(EXTENSION_ASSET_KINDS) && EXTENSION_ASSET_KINDS[:business]
      Account::Asset::BASIC_KINDS.merge(EXTENSION_ASSET_KINDS[:business])
    else
      Account::Asset::BASIC_KINDS
    end
  end

  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password
  before_create :make_activation_code
  attr_accessible :login, :email, :password, :password_confirmation
  after_destroy :destroy_deals, :destroy_accounts

  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login] # need to get the salt
    u && u.authenticated?(password) ? u.upgrade!(password) : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def update_password_token
    self.password_token_expires_at = 3.days.from_now.utc
    self.password_token            = encrypt("p-#{email}--#{password_token_expires_at}")
    save(false)
  end

  def password_token?
    password_token_expires_at && Time.now.utc < password_token_expires_at 
  end
  
  def change_password(password, password_confirmation)
    self.password = password
    self.password_confirmation = password_confirmation
    result = false
    User.transaction do
      result = save
      # パスワードが変更できたら、activateして、クラスを強制的に変える
      if result
        self.password_token = nil
        self.password_token_expires_at = nil
        unless self.active?
          @activated = true
          self.activated_at = Time.now.utc
          self.activation_code = nil
        end
        self[:type] = nil
        save(false)
      end
    end
    result
  end
  
  def update_attributes_with_password(attributes, password, password_confirmation)
    self.attributes = attributes
    if (!password.blank?)
      self.password = password
      self.password_confirmation = password_confirmation
    end
    User.transaction do 
      result = save
      # 最新方式でない暗号化方式だった場合は、パスワードを変更したらクラスを最新にする
      if result && !password.blank? && self[:type]
        self[:type] = nil
        save(false)
      end
      result
    end
  end
  
  # 新方式に変更する。基盤クラスなら何もしない。change_pass
  def upgrade!(password)
    return self if self.instance_of?(User)
    
    raise "Could not upgrade" unless change_password(password, password)
    User.find(self.id)
  end

  # == 家計簿ロジック TODO: モジュールへの切り出し ==
  
  # 指定した月の支出合計を得る
  # TODO: メソッド廃止
  def expenses_summary(year, month)
    # 期間を用意
    start_date = Date.new(year.to_i, month.to_i, 1)
    end_date = start_date >> 1

    accounts.expense_sum(start_date, end_date)
  end  
  
  # 指定した月の末日の資産合計、純資産合計の配列を得る
  def assets_summary(year, month)
    date = Date.new(year.to_i, month.to_i, 1) >> 1
    assets = accounts.balances(date, "accounts.type != 'Income' and accounts.type != 'Expense'")
    assets_sum = 0
    pure_assets_sum = 0
    for a in assets
      pure_assets_sum += a.balance # 純資産は＋とーを単純に足す
      assets_sum += a.balance if a.balance > 0 # 資産合計は正の資産だけ足す
    end
    [assets_sum, pure_assets_sum]
  end

  
  def recent(months, &block)
    result = []
    dates = []
    today = Date.today
    day = today << (months-1)
    while(day <= Date.today)
      result << yield(self, day)
      dates << day
      day >>= 1
    end
    [result, dates]
  end
  
  protected
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
    
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def make_activation_code

    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  def after_create
    create_preferences()
    Account::Base.create_default_accounts(self.id)
  end

  private
  def destroy_deals
    # アカウントを削除する場合、口座が消せるようにするためにまずDealを消す
    Deal::Base.find_all_by_user_id(self.id).each{|d| d.destroy }
  end
  def destroy_accounts
    # アカウントを削除する場合の口座削除処理。dependentだと順序が思うようでないので自前でやる
    Account::Base.find_all_by_user_id(self.id).each{|a| a.destroy}
  end

  
end
