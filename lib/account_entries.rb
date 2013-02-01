# ある勘定の一定期間の記入を扱うためのクラス
class AccountEntries

  attr_reader :account, :from, :to, :entries, :balance_start, :balance_end, :pure_balance_end

  def initialize(account, from, to)
    @account = account
    @from = from
    @to = to

    find_entries

    calc_balances
  end

  private

  # entries を検索して時間順に取得
  def find_entries
    @entries = @account.entries.in_a_time_between(@from, @to).includes(:deal).order("account_entries.date, account_entries.daily_seq, account_entries.amount")
  end

  # 残高推移を取得
  def calc_balances
    @balance_start = @account.balance_before(@from) # 期間最初における残高（繰り越し残高）。資産では常に意味があるが、費用・収入はニーズ次第。

    pure_balance = 0 # 期間最初の時点の残高を0とした場合の残高
    @entries.each do |e|
      if e.balance?
        pure_balance += e.amount unless e.initial_balance?
      else
        # 確定のときだけ残高に反映
        raise "no deal in entry #{e.id} (deal_id : #{e.deal_id}" unless e.deal
        pure_balance += e.amount if e.deal.confirmed?
        # TODO: account_entry側の仕事にしたいかな
        e.partner_account_name = e.deal.partner_account_name_of(e) # 効率上自分で入れておく
      end
      e.pure_balance = pure_balance
    end
    @pure_balance_end = pure_balance
    @balance_end = @balance_start + @pure_balance_end
  end

end