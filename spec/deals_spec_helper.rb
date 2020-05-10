# 使う場合は個別に require, include する
module DealsSpecHelper

  # entries には
  # 口座id => 金額, 口座 => 金額,,, を指定
  def new_deal(year, month, day, entries = {})
    amount = entries.values.reject{|v| v < 0}.inject(0){|r, v| r += v.to_i}
    minus_account_id = nil
    plus_account_id = nil
    user_id = nil
    for key, value in entries

      account = case key
      when Symbol
        accounts(key)
      else
        key
      end

      user_id = account.user_id

      if value < 0
        minus_account_id = account.id
      else
        plus_account_id = account.id
      end
    end
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物",
      :debtor_entries_attributes => [{:account_id => plus_account_id, :amount => amount}],
      :creditor_entries_attributes => [{:account_id => minus_account_id, :amount => amount.to_i*-1}],
      :date => Date.new(year, month, day))
    d.user_id = user_id
    d
  end


end
