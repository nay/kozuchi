class BalanceSheetController < ApplicationController
  menu_group "家計簿"
  menu "貸借対照表"

  def show
    redirect_to monthly_balance_sheet_path(:year => current_year, :month => current_month)
  end

  def monthly
    self.current_vague_date = [params[:year], params[:month]]
    date = current_vague_date.beginning_of_month >> 1
    asset_accounts = current_user.accounts.balances(date, "accounts.type != 'Account::Income' and accounts.type != 'Account::Expense'") # TODO: マシにする
    @assets = AccountsBalanceReport.new(asset_accounts, date)
  end
  
end
