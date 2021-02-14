class AccountsBalanceReport
  attr_accessor :plus
  attr_accessor :minus
  attr_accessor :capital_fund
  attr_reader :sum, :profit

  # 口座リストと残高計算期日から報告内容を作成する
  # TODO: とりあえず残高入りのaccountsをもらう
  def initialize(accounts, date)
    @plus = Accounts.new # TODO: やだなあこれ
    @minus = Accounts.new
    @capital_fund = Accounts.new
    accounts.each do |account|
      if account.kind_of?(Account::Asset) && account.capital_fund?
        @capital_fund << account
      elsif account.balance >= 0
        @plus << account
      else
        @minus << account
      end
    end
    @plus.set_percentage
    @minus.set_percentage
    @capital_fund.set_percentage
    @sum = @plus.sum + @minus.sum + @capital_fund.sum
    @profit = @plus.sum + @minus.sum + @capital_fund.sum
  end
  
end