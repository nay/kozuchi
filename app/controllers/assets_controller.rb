class AssetsController < ApplicationController
  helper :graph
  menu_group "家計簿"
  menu "資産表"

  before_action :check_account

  def index
    year, month = read_target_date
    redirect_to monthly_assets_path(:year => year, :month => month)
  end

  def monthly
    write_target_date(params[:year], params[:month])
    @year, @month = read_target_date

    date = Date.new(@year.to_i, @month.to_i, 1) >> 1
    asset_accounts = current_user.accounts.balances(date, "accounts.type != 'Account::Income' and accounts.type != 'Account::Expense'") # TODO: マシにする
    @assets = AccountsBalanceReport.new(asset_accounts, date)
  end

end
