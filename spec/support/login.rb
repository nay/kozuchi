# -*- encoding : utf-8 -*-

# 太郎でログインしているとき
shared_context "太郎 logged in" do
  let!(:current_user) {users(:taro)}
  before do
    visit "/"
    fill_in "login", :with =>  "taro"
    fill_in "password", :with => "taro"
    click_button "ログイン"
    raise "Login Error!" if page.has_content?("ログインに失敗しました。")
  end
end
