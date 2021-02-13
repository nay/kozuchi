require 'time'

# TODO: このクラスはなくす方向で
class DateBox
  attr_accessor :year, :month, :day
  
  # 月はじめの日を返す
  def start_inclusive
    Date.new(year_i, month_i, 1)
  end
  
  # その月を越えた最初の日を返す
  def end_exclusive
    self.start_inclusive >> 1
  end
  
  def initialize(values = nil)
    return if !values
    @year = values["year"]
    @month = values["month"]
    @day = values["day"]
  end
  
  def self.this_month
    t = Time.zone.now
    DateBox.new("year" => t.year.to_s, "month" => t.month.to_s)
  end
  
  def self.today
    t = Time.zone.now
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
  
  def to_s
    return "#{@year}/#{@month}/#{@day}"
  end
  
  def to_date
    Date.new(year_i, month_i, day_i)
  end
end
