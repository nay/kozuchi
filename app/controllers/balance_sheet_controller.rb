class BalanceSheetController < ApplicationController
  include BookMenues
  layout 'main'
  
  before_filter :prepare_date, :load_user  

  # 貸借対照表の表示
  def index
    # asset と同じだけど ^^;
    date = Date.new(@target_month.year_i, @target_month.month_i, 1) >> 1
    @assets = AccountsBalanceReport.new(Account.find_all(session[:user].id, [1]), date)
  end
  
end
