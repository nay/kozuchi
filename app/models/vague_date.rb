# 日があるかもしれない年月
# 日があればその日を、なければその月全体を表す
class VagueDate
  attr_reader :year, :month, :day

  # day が月にない日（9月31日など）なら、その月の近い日に直す
  def initialize(year, month, day = nil)
    @year = year.to_i
    @month = month.to_i
    @day = day.to_s.empty? ? nil : day.to_i.clamp(1, end_of_month.day)
  end

  def self.from_date(date)
    new(date.year, date.month, date.day)
  end

  # to_s で作った文字列から作る
  def self.parse(string)
    new(*string.split('-'))
  end

  def beginning_of_month
    Date.new(year, month, 1)
  end

  def end_of_month
    beginning_of_month.end_of_month
  end

  # 表す期間。日があればその日だけ、なければその月全体
  def range
    day ? Date.new(year, month, day)..Date.new(year, month, day) : beginning_of_month..end_of_month
  end

  def ==(other)
    other.is_a?(VagueDate) && [year, month, day] == [other.year, other.month, other.day]
  end

  # 例: "2026-09"、"2026-09-26"
  def to_s
    day ? format('%04d-%02d-%02d', year, month, day) : format('%04d-%02d', year, month)
  end
end
