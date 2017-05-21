class SettlementSummaries

  attr_reader :years, :months, :previous_target_date, :next_target_date

  def initialize(user, account: nil, past: 9, future: 1, target_date: Time.zone.today)
    @target_date = target_date
    prepare_months(past: past, future: future, target_date: @target_date)

    @previous_target_date = @target_date << (past + future)
    @next_target_date = @target_date >> (past + future) if @target_date < Time.zone.today.beginning_of_month

    scope = user.settlements.includes(:account, :result_entry => :deal).order('deals.date DESC, settlements.id DESC')
    scope = where(account_id: account.id) if account
    @summaries = scope.group_by(&:account)

    unless account
      @credit_accounts = user.assets.credit
      @credit_accounts.each do |account|
        @summaries[account] = nil unless @summaries.keys.include?(account)
      end
      @summaries = @summaries.sort{|(a, av), (b, bv)| a.sort_key <=> b.sort_key}
    end
  end

  def each(&block)
    @summaries.each(&block)
  end

  private

  # 月情報を用意する
  def prepare_months(past: 9, future: 1, target_date: Time.zone.today)
    @months = []
    date = start_date = target_date.beginning_of_month << past
    end_date = target_date.beginning_of_month >> future

    while date <= end_date
      @months << date
      date = date >> 1
    end
    @years = @months.group_by(&:year)
  end

end
