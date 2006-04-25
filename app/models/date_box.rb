class DateBox
  attr_accessor :year, :month, :day
  
  def self.set(values)
     i = DateBox.new()
     i.year = values["year"]
     i.month = values["month"]
     i.day = values["day"]
     i
  end
  
  def DateBox.foo
    return new
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
