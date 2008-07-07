require 'digest/sha1'
class User < ActiveRecord::Base
#  N_('User|Password')
#  N_('User|Password confirmation')
  has_one   :preferences, :class_name => "Preferences", :dependent => :destroy
  has_many  :friends, :dependent => :destroy
  has_many  :friend_applicants, :class_name => 'Friend', :foreign_key => 'friend_user_id', :dependent => :destroy
  has_many  :accounts, :class_name => 'Account::Base', :dependent => :destroy, :include => [:associated_accounts, :any_entry], :order => 'accounts.sort_key' do

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
        Account::Base.find(:all, :select => "accounts.*, sum(account_entries.amount) as balance",
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
        Account::Base.find(:all, :select => "accounts.*, sum(account_entries.amount) as flow",
          :conditions => ["deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true],
          :group => 'accounts.id'
        ).each{|a| a.flow = a.flow.to_i}
      end
    end

    # 指定した期間における指定した口座の不明金を Accountモデルの一覧として得る。不明金は unknown カラムに格納される。
    # 不明金勘定の視点から、正負は逆にする。つまり、支出の不明金はプラスで出る。
    def unknowns(start_date, end_date, conditions = nil)
      with_joined_scope(conditions) do
        Account::Base.find(:all, :select => "accounts.*, sum(account_entries.amount) as unknown",
          :conditions => ["deals.type = 'Balance' and deals.confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance != ?", true, start_date, end_date, true],
          :group => 'accounts.id'
        ).each{|a| a.unknown = a.unknown.to_i; a.unknown *= -1}
      end
    end
  
    # 指定した account_type のものだけを抽出する
    # TODO: 遅いので修正する
    def types_in(*account_types)
      account_types = account_types.flatten
      self.select{|a| account_types.detect{|t| a.type_in?(t)} }
    end
    
    # ハッシュに指定された内容に更新する。typeも変更する。
    # udpate も update_all もすでにあるので一応別名でつけた。
    def update_all_with(all_attributes)
      return unless all_attributes
      Account::Base.transaction do
        for account in self
          account_attributes = all_attributes[account.id.to_s]
          next unless account_attributes
          account_attributes = account_attributes.clone
          # user_id は指定させない
          account_attributes.delete(:user_id)
          # 資産種類を変える場合はクラスを変える必要があるのでとっておく
          new_asset_name = account_attributes.delete(:asset_name)
          old_account_name = account.name
          account.attributes = account_attributes
          account.save!
          # type の変更
          if new_asset_name && new_asset_name != account.asset_name
            target_type = Account::Asset.asset_name_to_class(new_asset_name)
            # 変更可能なものでなければ例外を発生する
            raise Account::IllegalClassChangeException.new(old_account_name, new_asset_name) unless account.changable_asset_types.include? target_type
            # object ベースではできないので sql ベースで
            Account::Base.update_all("type = '#{Account::Asset.asset_name_to_class(new_asset_name)}'", "id = #{account.id}") 
          end
        end
      end
    end
    private
    def with_joined_scope(conditions, &block)
      with_scope :find => {:conditions => conditions, :joins => "inner join account_entries on accounts.id = account_entries.account_id inner join deals on account_entries.deal_id = deals.id"} do
        yield
      end
    end
  end
  
  has_many :deals, :class_name => 'BaseDeal', :extend => User::DealsExtension
  
  def default_asset
    accounts.types_in(:asset).first
  end

  # all logic has been moved into login_engine/lib/login_engine/authenticated_user.rb
  def login_id
    self.login
  end
  
  # 相手と、指定したレベル以上の友人か調べる
  def friend?(target, level = 1)
    interactive_friends(level).include?(target)
  end
  
  # 双方向に指定level以上のフレンドを返す
  def interactive_friends(level)
    # TODO 効率悪い
    friend_users = []
    for l in friends(true)
      friend_users << l.friend_user if l.friend_level >= level && l.friend_user.friends(true).detect{|e|e.friend_user_id == self.id && e.friend_level >= level}
    end
    return friend_users
  end

  def self.find_friend_of(user_id, login_id)
    if 2 == Friend.count(:joins => "as fr inner join users as us on ((fr.user_id = us.id and fr.friend_user_id = #{user_id}) or (fr.user_id = #{user_id} and fr.friend_user_id = us.id))",
                   :conditions => ["us.login = ? and fr.friend_level > 0", login_id])
      return find_by_login_id(login_id)
    end
  end

  def self.is_friend(user1_id, user2_id)
    return 2 == Friend.count(:conditions => ["(user_id = ? and friend_user_id = ? and friend_level > 0) or (user_id = ? and friend_user_id == ? and friend_level > 0)", user1_id, user2_id, user2_id, user1_id])
  end


  def self.find_by_login_id(login_id)
    find(:first, :conditions => ["login = ? ", login_id])
  end
  
  def deal_exists?(date)
    BaseDeal.exists?(self.id, date)
  end
  
  # このユーザーが使える asset_type (Class) リストを返す
  def available_asset_types
    Account::Asset.types.find_all{|type| !type.business_only? || preferences.business_use? }
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

  
end
