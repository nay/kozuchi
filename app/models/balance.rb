# 残高確認記入行クラス
class Balance < BaseDeal
  attr_accessor :account_id, :balance
  
  validates_presence_of :balance, :message => '残高を入力してください。'

  def before_validation
    # もし金額にカンマが入っていたら正規化する
    @balance = @balance.gsub(/,/,'')  if @balance.class == String
  end

  def before_create
    self.summary = ""
    account_entries.build(:user_id => user_id, :account_id => @account_id, :amount => 0, :balance => @balance)
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
  
  private
  def create_entry
    account_entries.create(:user_id => user_id, :account_id => @account_id, :amount => 0, :balance => @balance)
  end

end