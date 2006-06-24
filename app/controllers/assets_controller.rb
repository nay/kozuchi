class AssetsController < ApplicationController
  include BookMenues
  layout 'main'
  before_filter :check_account

  def index
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month
    prepare
  end
  
  def update
    @target_month = DateBox.new(params[:target_month])
    prepare
    render(:partial => "assets", :layout => false)
  end
  
  private
  
  # 資産口座の期末残高一覧を表示して合計を出す。
  def prepare
    date = Date.new(@target_month.year_i, @target_month.month_i, 1) >> 1
    @assets = AccountsBalanceReport.new(Account.find_all(session[:user].id, [1]), date)
  end

end