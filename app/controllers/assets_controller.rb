class AssetsController < ApplicationController
  layout 'main'
  helper :graph
  menu_group "家計簿"
  menu "資産表"

  include WithCalendar

  before_filter :check_account

  def index
    year, month = read_target_date
    redirect_to monthly_assets_path(:year => year, :month => month)
  end

  def monthly
    @year = params[:year]
    @month = params[:month]

    date = Date.new(@year.to_i, @month.to_i, 1) >> 1
    asset_accounts = current_user.accounts.balances(date, "accounts.type != 'Income' and accounts.type != 'Expense'") # TODO: マシにする
    @assets = AccountsBalanceReport.new(asset_accounts, date)
  end

end
