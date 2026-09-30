class BalanceSheetController < ApplicationController
  menu_group "家計簿"
  menu "貸借対照表"

  def show
    redirect_to monthly_balance_sheet_path(:year => current_vague_date.year, :month => current_vague_date.month)
  end

  def monthly
    @year = params[:year]
    @month = params[:month]

    date = Date.new(@year.to_i, @month.to_i, 1) >> 1
    asset_accounts = current_user.accounts.balances(date, "accounts.type != 'Account::Income' and accounts.type != 'Account::Expense'") # TODO: マシにする
    @assets = AccountsBalanceReport.new(asset_accounts, date)
  end
  
end
