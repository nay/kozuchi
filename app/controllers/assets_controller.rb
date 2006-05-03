class AssetsController < BookController

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
    @assets = Accounts.new(Account.find_all(session[:user].id, [1]))
    date = Date.new(@target_month.year_i, @target_month.month_i, 1) >> 1
    @balance_sum = @assets.balance_before(date)
  end

end