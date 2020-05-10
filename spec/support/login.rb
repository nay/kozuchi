# 太郎でログインしているとき
shared_context "太郎 logged in" do
  let!(:current_user) {users(:taro)}
  before do
    visit "/"
    fill_in "login", :with =>  "taro"
    fill_in "password", :with => "taro"
    click_button "ログイン"
    raise "Login Error!" if page.has_content?("失敗しました。")
  end
end

# no_mobile_ident_userでログインしているとき
shared_context "no_mobile_ident_user logged in" do
  let!(:current_user) {users(:no_mobile_ident_user)}
  before do
    visit "/"
    fill_in "login", :with =>  "no_mobile_ident_user"
    fill_in "password", :with => "test"
    click_button "loginButton"
    raise "Login Error!" if page.has_content?("失敗しました。")
  end
end
