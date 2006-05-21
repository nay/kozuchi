# 口座リストクラス
# 口座の集合に対する処理、合計などを行う

class Accounts
  attr_reader :sum

  def initialize
    @list = []
    @sum = 0
  end
  
  def <<(account)
    @list << account
    @sum += account.balance
  end
  
  def each(&block)
    @list.each(&block)
  end
  
  def set_percentage
    each do |account|
      account.percentage = 
        @sum != 0 ? (100.0 * account.balance / @sum).round : 0
    end
  end
  
  def to_s
    @list.to_s
  end

end

