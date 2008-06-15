# 残高確認記入行クラス
# TODO: 登録、更新の処理の統一
# TODO: もう少しAccountオブジェクトを使ように設計変更
class Balance < BaseDeal
  attr_writer :account_id, :balance
  
  validates_presence_of :balance, :message => '残高を入力してください。'

  after_save :update_initial_balance
  after_destroy :update_initial_balance

  def initial_balance?
    entry.initial_balance?
  end

  # TODO: 関連にかえていく
  def entry
    raise "Invalid Balance #{id} with no account_entries" if account_entries.empty?
    account_entries.first
  end
  
  def before_validation
    # もし金額にカンマが入っていたら正規化する
    @balance = @balance.gsub(/,/,'')  if @balance.class == String
  end

  def before_create
    self.summary = ""
    amount = @balance.to_i - balance_before
    account_entries.build(:user_id => user_id, :account_id => @account_id, :amount => amount, :balance => @balance)
  end
  
  def before_update
    account_entries.clear
    create_entry
  end

  # Prepare sugar methods
  def after_find
    set_old_date
#    raise "Invalid Balance #{id} with no account_entries" if account_entries.empty?
#    @account_id = account_entries[0].account_id
#    @balance = account_entries[0].balance
  end
  
  def account_id
    @account_id ||= entry.account_id
    @account_id
  end
  
  def balance
    @balance ||= entry.balance
    @balance
  end
  
  def amount
    entry.amount
  end
  
  # amount（最初の残高以外は不明金として扱われる）を再計算して更新
  # 自分が「最初の残高」なら、最初の残高を考慮しない残高計算をする
  def update_amount
    e = account_entries.first
    amount = e.balance.to_i - balance_before(e.initial_balance?)
    e.update_attribute(:amount, amount)
  end
  
  def asset
    Account::Base.find(self.account_id)
  end
  
  private
  # 対象口座のinitial_balance値を更新する
  def update_initial_balance
    raise "no account_id" unless @account_id
    initial_balance_entry = AccountEntry.find(:first, 
      :joins => "inner join deals on deals.id = account_entries.deal_id",
      :conditions => "account_entries.account_id = #{@account_id} and deals.type='Balance'", :order => "deals.date, deals.daily_seq", :readonly => false)
    # 現在ひとつもないなら特に仕事なし
    return unless initial_balance_entry
    # すでにマークがついていたら仕事なし
    return if initial_balance_entry.initial_balance?

    # マークがついていない＝状態が変わったので修正する
    AccountEntry.update_all(["initial_balance = ?", false], ["account_id = ?", @account_id])
    AccountEntry.update_all(["initial_balance = ?", true], ["id = ?", initial_balance_entry.id])
    self.entry.initial_balance = true if self.entry.id == initial_balance_entry.id
  end
  
  def create_entry
    # 不明金による出納を計算して入れる。本来の残高＋不明金＝指定された残高　なので　不明金＝指定された残高ー本来の残高
    # 自分が「最初の残高」ならフラグを立てる
    amount = self.balance.to_i - balance_before
    account_entries.create(:user_id => self.user_id, :account_id => self.account_id, :amount => amount, :balance => self.balance)
  end
  
  def balance_before(ignore_initial = false)
    raise "date or daily_seq is nil!" unless self.date && self.daily_seq
    asset.balance_before(self.date, self.daily_seq, ignore_initial)
  end
end