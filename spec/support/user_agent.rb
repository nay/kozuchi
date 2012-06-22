# -*- encoding : utf-8 -*-

# AUからのアクセス
shared_context "requested from AU" do
  before do
    page.driver.header("x-up-subno", "01234567890123_xx.ezweb.ne.jp")
    page.driver.header("User-Agent", "KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0")
  end
end

# 簡単ログイン設定あり（AU）
shared_context "with the passport for AU" do
  let!(:current_user) {users(:no_mobile_ident_user)}
  before do
    current_user.update_mobile_identity!("01234567890123_xx.ezweb.ne.jp", "KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0")
  end
end