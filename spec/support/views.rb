# -*- encoding : utf-8 -*-

# ビュー○○が表示されている　ことの examples
# ほかのコントローラからの遷移の確認などで複数スペックで共通利用されるもの

shared_examples "users/new" do
  it {page.should have_content("ようこそ小槌へ！")}
  it {page.should have_css("form#signupForm")}
end

shared_examples "users/forgot_password" do
  it {page.should have_content("パスワードを忘れたとき")}
end

