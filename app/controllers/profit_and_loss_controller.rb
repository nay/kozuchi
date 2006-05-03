class ProfitAndLossController < BookController 

  # 収支表
  def index
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
    prepare_update_profit_and_loss
  end
  
  def update
    @target_month = DateBox.new(params[:target_month])
    prepare_update_profit_and_loss
    render(:partial => "profit_and_loss", :layout => false)
  end
  
  private

  def prepare_update_profit_and_loss
    # 費目ごとの合計を得る
    start_inclusive = Date.new(@target_month.year_i, @target_month.month_i, 1)
    end_exclusive = start_inclusive >> 1
    values = AccountEntry.sum(:amount,
     :group => 'account_id',
     :conditions => ["dl.date >= ? and dl.date < ?", start_inclusive, end_exclusive],
     :joins => "as et inner join deals as dl on dl.id = et.deal_id")
    expense_accounts = Account.find_all(session[:user].id, [2])
    @expenses_summaries = []
    for account in expense_accounts
      @expenses_summaries << AccountSummary.new(account, values[account.id] || 0)
    end
    # 収入項目ごとの合計を得る
    @incomes_summaries = []
    income_accounts = Account.find_all(session[:user].id, [3])
    for account in income_accounts
      @incomes_summaries << AccountSummary.new(account, values[account.id] ? values[account.id]*-1: 0)
    end
    
    # 各資産口座のその月の不明金の合計（プラスかマイナスかはわからない。不明収入と不明支出は相殺する。）を得る
    # TODO 同じ account_summaries でも口座増減と不明金は意味が違い気持ちがわるい
    asset_accounts = Account.find_all(session[:user].id, [1])
    @asset_plus_summaries = []
    @asset_minus_summaries = []
    for account in asset_accounts
      balance_start = AccountEntry.balance_at_the_start_of(session[:user].id, account.id, start_inclusive) # 期首残高
      balance_end = AccountEntry.balance_at_the_start_of(session[:user].id, account.id, end_exclusive) # 期末残高
      diff = balance_end - balance_start
      if diff > 0
        @asset_plus_summaries << AccountSummary.new(account, 0, diff)
      end
      if diff < 0
        @asset_minus_summaries << AccountSummary.new(account, 0, diff)
      end
      # 増減なしなら報告しない

      unknown_amount = balance_end - balance_start - (values[account.id] || 0)
      if unknown_amount > 0
        @incomes_summaries << AccountSummary.new(account, unknown_amount)
      else
        if unknown_amount < 0
          @expenses_summaries << AccountSummary.new(account, unknown_amount.abs)
        end
      end
      # 不明金0なら報告しない
      @expenses_sum = AccountSummary.get_sum(@expenses_summaries)
      @incomes_sum = AccountSummary.get_sum(@incomes_summaries)
      @profit = @incomes_sum - @expenses_sum
      @assets_plus_sum = AccountSummary.get_diff_sum(@asset_plus_summaries)
      @assets_minus_sum = AccountSummary.get_diff_sum(@asset_minus_summaries)

      session[:target_month] = @target_month
    end
    
  end
end