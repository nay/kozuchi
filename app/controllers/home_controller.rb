class HomeController < ApplicationController
  
  def index
    today = Date.today
    @monthly_expense = @user.expense_summary(today.year, today.month)
    @summary_item = ["支出合計"]
    @months = ["月"]
    # 前５ヶ月分を計算
    day = today << 5
    while(@summary_item.size < 6)
      @summary_item << @user.expense_summary(day.year, day.month)
      @months << "#{day.month}月"
      day = day >> 1
    end
    @summary_item << @monthly_expense
    @months << "#{today.month}月"
#    today = Date.today
#    redirect_to :controller => 'deals', :year => today.year, :month => today.month
  end
end
