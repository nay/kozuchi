class Account::Base < ActiveRecord::Base

  set_table_name "accounts"

  include Account::Common
  
  has_many :entries, :class_name => "Entry::Base", :foreign_key => "account_id"
  has_many :balances, :class_name => "Entry::Balance", :foreign_key => "account_id"

  has_many :deals, :through => :entries, :order => "deals.date, deals.daily_seq"

  # DBを検索してDBに格納された名前を得る
  # オブジェクトに格納されたnameが格納された名前と異なる場合があるので用意
  def stored_name
    raise "not stored" if new_record?
    self.class.find(self.id).name
  end

  # ---------- 口座種別の静的属性を設定するためのメソッド群
  # すぐ下の派生クラスの配列を返す。Base は口座種別、Assetは資産種別となる
  def self.types
    [Account::Asset, Account::Expense, Account::Income]
#    @types ||= []
#    return @types.clone
  end

  # クラス名に対応する Symbol　を返す。  
  def self.to_sym
    self.name.demodulize.underscore.to_sym
  end
  
  # Symbolに対応するクラスを返す。Accountモジュール下にないクラスの場合は例外を発生する。
  # sym:: Symbol
  def self.sym_to_class(sym)
    eval "Account::#{sym.to_s.camelize}" # ネストしたクラスなので eval で
  end
  
  def type_in?(type)
    t = self.class.sym_to_class(type) unless type.kind_of?(Class) # TODO: Classのとき動かなそうだな
    self.kind_of? t
  end

  # 勘定種類のセレクションボックスでのソートに利用する
  def self.selection_order(order = nil)
    @selection_order ||= 0
    return @selection_order unless order
    @selection_order = order
  end


  # 継承されたときは口座種類配列を更新する
 # def self.inherited(subclass)
 #   @types ||= []
 #   @types << subclass unless @types.include?(subclass)
 #   super
 # end
  
  def self.type_order(order = nil)
    @type_order ||= 0
    return @type_order unless order
    @type_order = order
  end
  
#  # 口座種類配列をソートする
#  def self.sort_types
#    @types ||= []
#    @types.sort!{|a, b| a.type_order <=> b.type_order}
#  end
  
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
  # TODO: リファクタリングしたい
  def name_with_asset_type
    "#{self.name}(#{self.class.short_name})"
  end

  # TODO: 呼び出し側のリファクタリング確認
  # with_asset_type の前にユーザー名をつけたもの
  def name_with_user
    return "#{user.login_id} さんの #{name_with_asset_type}"
  end
  
  # ---------- 機能

  belongs_to :user

  belongs_to              :partner_account,
                          :class_name => 'Account::Base',
                          :foreign_key => 'partner_account_id'

  # any_entry:: 削除可能性チェックのために用意。削除可能性チェック結果表示のための一覧では include すること。
  has_one                 :any_entry,
                          :class_name => 'Entry::Base',
                          :foreign_key => 'account_id'
  
#  attr_accessor :balance, 
  attr_accessor :percentage
  validates_presence_of :name,
                        :message => "名前を定義してください。"
  #TODO: 口座・費目・収入内訳を動的に作りたいが、現状の方針だとできない 
  validates_uniqueness_of :name, :scope => 'user_id', :message => "口座・費目・収入内訳で名前が重複しています。"
  validate :validates_partner_account
  before_destroy :assert_not_used

  # 削除可能性を調べる
  def deletable?
    @delete_errors = []
    begin
      assert_not_used(false) # キャッシュを使う
      return true
    rescue Account::Base::UsedAccountException => err
      delete_errors << err.message
      return false
    end
  end
  
  # deletable? を実行したときに更新される削除エラーメッセージの配列を返す。
  def delete_errors
    @delete_errors ||= []
    @delete_errors
  end

  # 連携設定 ------------------
  include Account::Linking

  def self.get(user_id, account_id)
    return Account::Base.find(:first, :conditions => ["user_id = ? and id = ?", user_id, account_id])
  end
  
  def self.get_by_name(user_id, name)
    return Account::Base.find(:first, :conditions => ["user_id = ? and name = ?", user_id, name])
  end

  def to_s
    "#{self.class.name}:#{id}:#{object_id}(#{user ? user.login : user_id} : #{name})"
  end

  # 口座別計算メソッド
  
  # 指定された日付より前の時点での残高を計算して balance に格納する
  def balance_before(date, daily_seq = 0, ignore_initial = false)
#    p "balance_before : #{date.to_s(:db)} - #{daily_seq} : #{ignore_initial}"
    # 確認済のものだけカウントする
#    conditions = ["deals.confirmed = ? and (deals.date < ? or (deals.date = ? and deals.daily_seq < ?))", true, date, date, daily_seq]
    conditions = ["deals.confirmed = ? and (account_entries.date < ? or (account_entries.date = ? and account_entries.daily_seq < ?))", true, date, date, daily_seq]
    if !ignore_initial
      conditions.first.replace("(#{conditions.first}) or account_entries.initial_balance = ?")
      conditions << true
    end
#    p entries.find(:all,
#      :joins => "inner join deals on entries.deal_id = deals.id",
#      :conditions => conditions).inspect
    entries.sum(:amount,
      :joins => "inner join deals on account_entries.deal_id = deals.id",
      :conditions => conditions
      ) || 0      
  end

  # 指定した期間の支出合計額（不明金を換算しない）を得る
  def raw_sum_in(start_date, end_date)
    Entry::Base.sum(:amount,
      :joins => "inner join deals on deals.id = account_entries.deal_id",
      :conditions => ["account_id = ? and deals.date >= ? and deals.date < ?", self.id, start_date, end_date]
    ) || 0
  end

  # 口座の初期設定を行う
  def self.create_default_accounts(user_id)
    # 口座
    Account::Asset.create_accounts(user_id, :cache, ['現金'])
    # 支出
    Account::Expense.create_accounts(user_id, ['食費','住居・備品','水・光熱費','被服・美容費','医療費','理容衛生費','交際費','交通費','通信費','教養費','娯楽費','税金','保険料','雑費','予備費','教育費','自動車関連費'])
    # 収入
    Account::Income.create_accounts(user_id, ['給料', '賞与', '利子・配当', '贈与'] )
  end

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.tag!(serialized_type_name, XMLUtil.escape(self.name), serialized_attributes)
  end

  def to_csv
    attrs = serialized_attributes
    [serialized_type_name, id, attrs[:type], attrs[:position], "\"#{name}\""].join(',')
  end

  private
  def serialized_attributes
    {:id => "account#{self.id}", :position => self.sort_key}
  end

  def serialized_type_name
    self.class.name.split('::').last.underscore
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
  
  # 使われていないことを確認する。
  # force:: true ならその時点でデータベースを新しく調べる。 false ならキャッシュを利用する。
  def assert_not_used(force = true)
    # 使われていたら消せない
    raise Account::Base::UsedAccountException.new(self.class.type_name, name) if self.any_entry(force)
  end

end

# require ではrails的に必要な文脈で確実にリロードされないので参照する
#for d in Dir.glob(File.expand_path(File.dirname(__FILE__)) + '/*')
#  clazz = d.scan(/.*\/account\/(.*).rb$/).to_s.camelize
#  eval clazz
#end
#ObjectSpace.each_object(Class){|o| o}

#Account::Base.sort_types
#Account::Asset.sort_types

# データがある勘定を削除したときに発生する例外
# TODO: なんとかしたい
class Account::Base::UsedAccountException < Exception
  def initialize(account_type_name, account_name)
    super(self.class.new_message(account_type_name, account_name))
  end
  def self.new_message(account_type_name, account_name)
    "#{account_type_name}「#{account_name}」はすでに使われているため削除できません。"
  end
end