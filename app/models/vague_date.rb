# 日があるかもしれない年月
# 日があればその日を、なければその月全体を表す
class VagueDate
  attr_reader :year, :month, :day

  # 日がないのに Date が必要になったとき
  class NoDayError < StandardError; end

  # day が月にない日（9月31日など）なら、その月の近い日に直す
  def initialize(year, month, day = nil)
    @year = year.to_i
    @month = month.to_i
    @day = day.to_s.empty? ? nil : day.to_i.clamp(1, end_of_month.day)
  end

  def self.from_date(date)
    new(date.year, date.month, date.day)
  end

  # VagueDate、Date、[年, 月]、[年, 月, 日] のどれかから作る
  def self.from(value)
    case value
    when VagueDate then value
    when Date then from_date(value)
    when Array then new(*value)
    else raise ArgumentError, "#{value.inspect} から VagueDate を作れません"
    end
  end

  # to_s で作った文字列から作る
  def self.parse(string)
    new(*string.split('-'))
  end

  def beginning_of_month
    @beginning_of_month ||= Date.new(year, month, 1)
  end

  def end_of_month
    @end_of_month ||= beginning_of_month.end_of_month
  end

  # 日がなければ NoDayError
  def to_date
    raise NoDayError, "#{self} には日がありません" unless day

    @to_date ||= Date.new(year, month, day)
  end

  # 日があるかどうかはそのままに、date に移した VagueDate。日があれば date の日、なければ date の月
  def move_to(date)
    day ? VagueDate.from_date(date) : VagueDate.new(date.year, date.month)
  end

  # 表す期間。日があればその日だけ、なければその月全体
  def range
    day ? to_date..to_date : beginning_of_month..end_of_month
  end

  def ==(other)
    other.is_a?(VagueDate) && [year, month, day] == [other.year, other.month, other.day]
  end

  # 例: "2026-09"、"2026-09-26"
  def to_s
    day ? format('%04d-%02d-%02d', year, month, day) : format('%04d-%02d', year, month)
  end
end
