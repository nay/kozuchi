# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def format_date(date)
    date.strftime('%Y/%m/%d')
  end
end
