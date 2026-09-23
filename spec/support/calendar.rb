# 押した月が選ばれた状態になるまで待つ
# 記入画面では、ページを読み直さずに Turbo Frame の中身を入れ替えるので、その後始末が終わるまで待つ
def click_calendar(year, month)
  find("#month_#{year}_#{month} a").click
  expect(page).to have_css("td.selected_month#month_#{year}_#{month}")
  wait_for_turbo_frame_navigation if page.has_css?("turbo-frame", visible: :all, wait: false)
end

def selected_month_text
  find("td.selected_month").text
end
