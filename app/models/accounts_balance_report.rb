class AccountsBalanceReport
  attr_accessor :plus
  attr_accessor :minus
  attr_reader :sum

  # 口座リストと残高計算期日から報告内容を作成する
  def initialize(accounts, date)
    @plus = Accounts.new
    @minus = Accounts.new
    accounts.each do |account|
      if account.balance_before(date) >= 0
        @plus << account
      else
        @minus << account
      end
    end
    @plus.set_percentage
    @minus.set_percentage
    @sum = @plus.sum + @minus.sum
  end
  
end