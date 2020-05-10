class ProfitAndLossController < ApplicationController
  helper :graph
  menu_group "家計簿"
  menu "収支表"

  before_action :check_account

  def show
    year, month = read_target_date
    redirect_to monthly_profit_and_loss_path(:year => year, :month => month)
  end

  def monthly
    write_target_date(params[:year], params[:month])
    @year, @month = read_target_date

    # 費目ごとの合計を得る
    start_inclusive = Date.new(@year.to_i, @month.to_i, 1)
    end_exclusive = start_inclusive >> 1

    # 全口座のフローを得る
    flows = current_user.accounts.flows(start_inclusive, end_exclusive)

    # 前月のデータを得る
    previous_flows = current_user.accounts.flows(start_inclusive << 1, end_exclusive << 1)

    # 表示用のインスタンス変数に格納していく
    @expense_flows = Flow::PlusList.new
    @income_flows = Flow::MinusList.new
    @asset_plus_flows = Flow::PlusList.new
    @asset_minus_flows = Flow::MinusList.new
    for account in flows
      previous = previous_flows.detect{|pa| pa.id == account.id}
      previous_flows.delete(previous)
      case account
        when Account::Expense
          @expense_flows.add_with_previous(account, previous)
        when Account::Income
          @income_flows.add_with_previous(account, previous)
        else
          if account.flow > 0
            @asset_plus_flows.add_with_previous(account, nil)
          elsif account.flow < 0
            @asset_minus_flows.add_with_previous(account, nil)
         end
      end
    end
    # 今月なくて前月あるものを加える
    for previous in previous_flows
      case previous
        when Account::Expense
          @expense_flows.add_with_previous(nil, previous)
        when Account::Income
          @income_flows.add_with_previous(nil, previous)
      end
    end

    # 不明金を得て、収支に加える
    unknowns = current_user.accounts.unknowns(start_inclusive, end_exclusive)
    previous_unknowns = current_user.accounts.unknowns(start_inclusive << 1, end_exclusive << 1)
    for account in unknowns
      previous = previous_unknowns.detect{|pk| pk.id == account.id}
      if account.unknown > 0
        @expense_flows.add_with_previous(account, previous)
      elsif account.unknown < 0
        @income_flows.add_with_previous(account, previous)
      end
    end
    # 今月なくて前月あるものを加える
    for previous in previous_unknowns
      case previous
        when Account::Expense
          @expense_flows.add_with_previous(nil, previous)
        when Account::Income
          @income_flows.add_with_previous(nil, previous)
      end
    end

    @profit = @income_flows.sum - @expense_flows.sum
  end
  
end
