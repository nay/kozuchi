require File.dirname(__FILE__) + '/../test_helper'

class DateBoxTest < Test::Unit::TestCase

  def test_set
    values = {"year" => "2004", "month" => "4"}
    d = DateBox.new(values)
    assert_equal "2004", d.year
    assert_equal "4", d.month
    assert_equal nil, d.day
  end
end