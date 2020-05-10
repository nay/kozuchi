require 'spec_helper'

describe WelcomeController, type: :feature do
  fixtures :users, :accounts, :preferences

  shared_examples "index" do
    it {expect(page).to have_content('きちんと。気楽に。')}
  end

  shared_examples "having login form" do
    it {expect(page).to have_css("input#login")}
  end
  
  shared_examples "not having login form" do
    it {expect(page).not_to have_css("input#login")}
  end

  describe "GET /" do
    context "when not logged in" do

      before do
        visit "/"
      end
      it_behaves_like "index"
      it_behaves_like "having login form"
    end


    context "when logged in" do
      include_context "太郎 logged in"

      before do
        visit "/"
      end
      it_behaves_like "index"
      it_behaves_like "not having login form"
    end

    describe "「アカウント登録して使い始める（無料）」ボタンのクリックで遷移する" do
      before do
        visit "/"
        click_link("アカウント登録して使い始める（無料）")
      end
      it_behaves_like "users/new"
    end

    describe "link パスワードを忘れたとき (when not logged in)" do
      before do
        visit "/"
        click_link("パスワードを忘れたとき")
      end
      it_behaves_like "forgot_password (メール送信あり)"
    end

  end

end
