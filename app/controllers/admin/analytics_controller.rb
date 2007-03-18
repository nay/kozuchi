class Admin::AnalyticsController < Admin::AdminController

  def users
    @users = User.find(:all)
    
    @spans = []
    date = User.minimum(:created_at, :conditions => 'logged_in_at is not null')
    date = Date.new(date.year, date.month, 1)
    next_month = Date.new(Time.now.year, Time.now.month, 1) >> 1
    while date < next_month
      @spans << [date.year, date.month]
      date = (date >> 1)
    end
  end


end
