def click_calendar(year, month)
  find("#month_#{year}_#{month} a").click
end

def selected_month_text
  find("td.selected_month").text
end
