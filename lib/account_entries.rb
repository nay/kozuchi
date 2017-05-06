# ある勘定の一定期間の記入を扱うためのクラス
class AccountEntries

  attr_reader :account, :from, :to, :entries, :balance_start, :balance_end, :pure_balance_end

  delegate :last, :first, :any?, to: :entries

  def initialize(account, from, to)
    @account = account
    @from = from
    @to = to

    find_entries

    calc_balances
  end

  # deal, entries をブロックに渡す
  def each(&block)
    @deals.each do |deal|
      yield deal, deal.readonly_entries.find_all{|e| e.account_id == @account.id}
    end
  end

  private

  # entries を検索して時間順に取得
  def find_entries
    @deals = account.user.deals.in_a_time_between(@from, @to).joins("INNER JOIN account_entries ON account_entries.deal_id = deals.id").on(@account).includes(:readonly_entries).distinct.order(:date, :daily_seq)
    @entries = @deals.map{|d| d.readonly_entries.find_all{|e| e.account_id == @account.id}}.flatten
  end

  # 残高推移を取得
  def calc_balances
    @balance_start = @account.balance_before(@from) # 期間最初における残高（繰り越し残高）。資産では常に意味があるが、費用・収入はニーズ次第。

    pure_balance = 0 # 期間最初の時点の残高を0とした場合の残高
    @entries.each do |e|
      if e.balance?
        pure_balance += e.amount unless e.initial_balance?
      else
        deal = @deals.detect{|d| e.deal_id == d.id}
        # 確定のときだけ残高に反映
        pure_balance += e.amount if deal.confirmed?
        # TODO: account_entry側の仕事にしたいかな
        e.partner_account_name = deal.partner_account_name_of(e) # 効率上自分で入れておく
      end
      e.pure_balance = pure_balance
    end
    @pure_balance_end = pure_balance
    @balance_end = @balance_start + @pure_balance_end
  end

end
