# ユーザーに紐づくロジックは多いので、機能別にモジュールを記述してincludeする
require 'digest/sha1'
class User < ApplicationRecord
  require 'user/friend' # TODO: User::Friendのincludeが(少なくともdevelopmentモードで)エラーになるため応急措置
  include User::Friend

  delegate :bookkeeping_style?, :to => :preferences

  has_many  :single_logins, :dependent => :destroy
  has_many  :settlements, :dependent => :destroy
  has_one   :preferences, :class_name => "Preferences", :dependent => :destroy
  has_many  :incomes, -> { order(:sort_key) },
            class_name: 'Account::Income'
  has_many  :expenses, -> { order(:sort_key) },
            class_name: 'Account::Expense'
  has_many  :assets, -> { order(:sort_key) },
            class_name: "Account::Asset" do
    def credit
      credit_asset_kinds = asset_kinds{|attributes| attributes[:credit]}.map{|k| k.to_s}
      categorized_as(*credit_asset_kinds)
    end
  end
  has_many  :flow_accounts, -> { where("asset_kind is null").order(:sort_key) },
            class_name: "Account::Base"

  has_many :deal_patterns, :class_name => "Pattern::Deal"

  ACCOUNTS_OPTIONS_ASC = ['Account::Asset', 'Account::Income', 'Account::Expense']
  ACCOUNTS_OPTIONS_DESC = ['Account::Expense', 'Account::Asset', 'Account::Income']
  has_many  :accounts, -> { order(:sort_key) }, :class_name => 'Account::Base' do

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
      where(conditions)
          .join_entries_and_deals
          .where("(deals.confirmed = ? and deals.date < ?) or account_entries.initial_balance = ?", true, date, true)
          .sum("account_entries.amount")
          .to_i
    end
    
    # 指定した日の最初における指定した口座の残高をAccountモデルの一覧として得る
    def balances(date, conditions = nil)
      where(conditions)
          .join_entries_and_deals
          .select("accounts.*, sum(account_entries.amount) as balance")
          .includes(nil)
          .where("(deals.confirmed = ? and deals.date < ?) or account_entries.initial_balance = ?", true, date, true)
          .group('accounts.id')
          .each{|a| a.balance = a.balance.to_i }
    end
    
    # 指定した期間における収入口座のフロー合計を得る。収入の不明金も含める。
    def income_sum(start_date, end_date)
      result = flow_sum(start_date, end_date, "accounts.type = 'Account::Income'")
      unknowns(start_date, end_date).delete_if{|a| a.unknown >= 0}.each{|a| result += a.unknown}
      result
    end

    # 指定した期間における支出口座のフロー合計を得る。支出の不明金も含める。
    # end_date は exclusive
    # NOTE: 不明金は正負逆転するとか、正負をそれぞれよせるかまとめてよせるかなどがあり、SQL一発でやるのは難しい
    #   例えば 擬似的に views を作り、asset 勘定ごとに任意の方向で amount がとれるようにするといいのかもしれない
    #   不明金を合体させて扱うのは総合的なところに限られるので、Accountクラスに引っ越す必要性は高くなさそう
    def expense_sum(start_date, end_date)
#      TODO: 旧 flow_sum から 新 total_flow （accounts関連から accountsクラスメソッド系へ）へ移行中。参考のため残しておく
#      result = flow_sum(start_date, end_date, "accounts.type = 'Account::Expense'")
      result = expense.total_flow(start_date, end_date-1) # inclusive に修正...
      unknowns(start_date, end_date).delete_if{|a| a.unknown <= 0}.each{|a| result += a.unknown}
      result
    end
    
    # 指定した期間における指定した口座のフロー合計を得る。不明金は扱わない。
    def flow_sum(start_date, end_date, conditions = nil)
      where(conditions)
          .join_entries_and_deals
          .where("deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true)
          .sum("account_entries.amount")
          .to_i
    end
    
    # 指定した期間における指定した口座のフローをAccountモデルの一覧として得る。flowカラムに格納される。
    # 資産口座の不明金を結果に足すことはしない。
    # 記入のない口座は取得されない。
    def flows(start_date, end_date, conditions = nil)
      where(conditions)
          .join_entries_and_deals
          .select("accounts.*, sum(account_entries.amount) as flow")
          .includes(nil)
          .where("deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true)
          .group('accounts.id')
          .to_a.each{|a| a.flow = a.flow.to_i}
    end

    # 指定した期間における指定した口座の不明金を Accountモデルの一覧として得る。不明金は unknown カラムに格納される。
    # 不明金勘定の視点から、正負は逆にする。つまり、支出の不明金はプラスで出る。
    def unknowns(start_date, end_date, conditions = nil)
      where(conditions)
          .join_entries_and_deals
          .select("accounts.*, sum(account_entries.amount) as unknown")
          .includes(nil)
          .where("deals.type = 'Deal::Balance' and deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true)
          .group('accounts.id')
          .to_a.each{|a| a.unknown = a.unknown.to_i; a.unknown *= -1 }
        # Rails5.0にあげたとき、to_a をはさまずに each すると結果が frozen になってしまった
    end
  
    # 指定した account_type のものだけを抽出する
    # TODO: 遅いので修正する
#    def types_in(*account_types)
#      account_types = account_types.flatten
#      self.select{|a| account_types.detect{|t| a.type_in?(t)} }
#    end
    
  end

  after_create :create_defaults

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
    accounts.find_by(name: account_name)

#    AccountProxy.new(account_id)
  end

  include User::AccountLinking
  
  has_many :deals, :class_name => 'Deal::Base', :extend => User::DealsExtension
  # 作成用
  has_many :general_deals, :class_name => "Deal::General", :foreign_key => "user_id"
  has_many :balance_deals, :class_name => "Deal::Balance", :foreign_key => "user_id"

  has_many :entries,         class_name: "Entry::Base"
  has_many :general_entries, class_name: "Entry::General"
  
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
  
  # TODO: メソッド不要
  def self.find_by_login_id(login_id)
    find_by(login: login_id)
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

  validates :login, presence: true, length: {within: 3..40,  allow_blank: true}, uniqueness: {case_sensitive: false, allow_blank: true}
  validates :email, presence: true, length: {within: 3..100, allow_blank: true}, uniqueness: {case_sensitive: false, allow_blank: true}

  with_options if: :password_required? do |req|
    req.validates :password,              presence: true, length: {within: 4..40,  allow_blank: true}, confirmation: true
    req.validates :password_confirmation, presence: true
  end

  before_save :encrypt_password
  before_create :make_activation_code
  after_destroy :destroy_deals, :destroy_accounts

  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.zone.now.utc
    self.activation_code = nil
    save(:validate => false)
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = where('login = ? and activated_at IS NOT NULL', login).first # need to get the salt
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
    remember_token_expires_at && Time.zone.now.utc < remember_token_expires_at
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
    save(:validate => false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def update_password_token
    self.password_token_expires_at = 3.days.from_now.utc
    self.password_token            = encrypt("p-#{email}--#{password_token_expires_at}")
    save(:validate => false)
  end

  def password_token?
    password_token_expires_at && Time.zone.now.utc < password_token_expires_at
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
          self.activated_at = Time.zone.now.utc
          self.activation_code = nil
        end
        self[:type] = nil
        save(:validate => false)
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
        save(:validate => false)
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
    assets = accounts.balances(date, "accounts.type != 'Account::Income' and accounts.type != 'Account::Expense'")
    assets_sum = 0
    pure_assets_sum = 0
    for a in assets
      pure_assets_sum += a.balance # 純資産は＋とーを単純に足す
      assets_sum += a.balance if a.balance > 0 # 資産合計は正の資産だけ足す
    end
    [assets_sum, pure_assets_sum]
  end

  
  def recent(months, &block)
    recent_from(Time.zone.today, months, &block)
  end

  def recent_from(start_date, months, &block)
    result = []
    dates = []
    day = start_date << (months-1)
    while(day <= start_date)
      result << yield(self, day)
      dates << day
      day >>= 1
    end
    [result, dates]
  end

  # 最古の記入のある年
  def start_year
    @start_year ||= entries.minimum(:date).year
  end

  # 最古の記入のある年、古すぎるときは100年前
  def pragmatic_start_year
    [start_year, Time.zone.now.year - 100].max
  end

  protected
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.zone.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
    
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def make_activation_code

    self.activation_code = Digest::SHA1.hexdigest( Time.zone.now.to_s.split(//).sort_by {rand}.join )
  end

  private
  def create_defaults
    create_preferences
    Account::Base.create_default_accounts(self.id)
  end

  def destroy_deals
    # アカウントを削除する場合、口座が消せるようにするためにまずDealを消す
    Deal::Base.where(user_id: id).each{|d| d.destroy }
  end
  def destroy_accounts
    # アカウントを削除する場合の口座削除処理。dependentだと順序が思うようでないので自前でやる
    Account::Base.where(user_id: id).each{|a| a.destroy}
  end

  
end
