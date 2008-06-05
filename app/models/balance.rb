# 残高確認記入行クラス
# TODO: 登録、更新の処理の統一
class Balance < BaseDeal
  attr_accessor :account_id, :balance
  
  validates_presence_of :balance, :message => '残高を入力してください。'

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
    raise "Invalid Balance #{id} with no account_entries" if account_entries.empty?
    @account_id = account_entries[0].account_id
    @balance = account_entries[0].balance
  end
  
  # 不明金を再計算して更新
  def update_amount
    e = account_entries.first
    amount = e.balance.to_i - balance_before
    p "update_amount of #{self.id} - amount = #{e.amount} -> #{amount}"
    e.update_attribute(:amount, amount)
  end
  
  private
  def create_entry
    # 不明金による出納を計算して入れる。本来の残高＋不明金＝指定された残高　なので　不明金＝指定された残高ー本来の残高
    # 自分が「最初の残高」ならフラグを立てる
    amount = @balance - balance_before
    account_entries.create(:user_id => self.user_id, :account_id => @account_id, :amount => amount, :balance => @balance)
  end
  
  def balance_before
    raise "date or daily_seq is nil!" unless self.date && self.daily_seq
    AccountEntry.balance_before(@account_id, self.date, self.daily_seq)
  end
end