# 口座リストクラス
# 口座の集合に対する処理、合計などを行う

class Accounts
  def initialize(accounts = nil)
    @list = accounts || []
  end
  
  def <<(account)
    @list << account
  end
  
  def each(&block)
    @list.each(&block)
  end
  
  def balance_before(date)
    balance_sum = 0
    each do |account|
      balance_sum += account.balance_before(date)
    end
    each do |account|
      account.percentage = balance_sum != 0 ? (100*account.balance/balance_sum).to_i : 0
    end
    balance_sum
  end
  
  def to_s
    @list.to_s
  end

end