# Turbo の移動が、後始末まで終わるのを待つ
# 後始末の途中で次の移動や戻るをすると、Turbo が後始末の通信を取り消して AbortError になったり、URL と画面が食い違ったりするため

# Turbo Frame の中の移動（後始末として、履歴への記録と、移動前のページの控えの保存をする）
def wait_for_turbo_frame_navigation
  expect(page).to have_css("turbo-frame[complete]", visible: :all)
  wait_for_turbo_visit
end

# ページ単位の移動（戻る・進むを含む）
def wait_for_turbo_visit
  expect(page).to have_no_css("html[aria-busy]", visible: :all)
end
