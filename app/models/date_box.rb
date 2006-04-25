require 'time'

class DateBox
  attr_accessor :year, :month, :day
  
  def initialize(values = nil)
    return if !values
    @year = values["year"]
    @month = values["month"]
    @day = values["day"]
  end
  
  def self.this_month
    t = Time.now
    DateBox.new("year" => t.year.to_s, "month" => t.month.to_s)
  end
  
  def self.today
    t = Time.now
    DateBox.new("year" => t.year.to_s, "month" => t.month.to_s, "day" => t.day.to_s)
  end

  def year_i
    @year.to_i
  end
  
  def month_i
    @month.to_i
  end
  
  def day_i
    @day.to_i
  end
end
