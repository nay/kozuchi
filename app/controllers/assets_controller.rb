class AssetsController < ApplicationController
  helper :graph
  menu_group "家計簿"
  menu "資産表"

  before_action :check_account

  def index
    redirect_to monthly_assets_path(:year => current_year, :month => current_month)
  end

  def monthly
    self.current_vague_date = VagueDate.new(params[:year], params[:month])
    @year, @month = params[:year], params[:month]

    date = Date.new(@year.to_i, @month.to_i, 1) >> 1
    asset_accounts = current_user.accounts.balances(date, "accounts.type != 'Account::Income' and accounts.type != 'Account::Expense'") # TODO: マシにする
    @assets = AccountsBalanceReport.new(asset_accounts, date)
  end

end
