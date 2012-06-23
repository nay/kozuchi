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

# DoCoMoからのアクセス（X_DCMGUIDあり）
shared_context "requested from DoCoMo" do
  before do
    page.driver.header("X_DCMGUID", "0123456")
    page.driver.header("User-Agent", "DoCoMo/2.0 SH02A")
  end
end

# DoCoMoからのアクセス（X_DCMGUIDなし）
shared_context "requested from DoCoMo without X_DCMGUID" do
  before do
    page.driver.header("User-Agent", "DoCoMo/1.0/X503i/c10/ser")
  end
end

# DoCoMoからのアクセス（X_DCMGUIDなし, utn返信）
shared_context "requested from DoCoMo without X_DCMGUID for utn form" do
  before do
    page.driver.header("User-Agent", "DoCoMo/1.0/X503i/c10/ser98765432109")
  end
end

# 簡単ログイン設定あり（DoCoMo, X_DCMGUID）
shared_context "with the passport for DoCoMo" do
  let!(:current_user) {users(:no_mobile_ident_user)}
  before do
    current_user.update_mobile_identity!("0123456", "DoCoMo/2.0 SH02A")
  end
end

# 簡単ログイン設定あり（DoCoMo, utn）
shared_context "with the passport for DoCoMo via utn" do
  let!(:current_user) {users(:no_mobile_ident_user)}
  before do
    current_user.update_mobile_identity!("98765432109", "DoCoMo/1.0/X503i/c10/ser98765432109")
  end
end
