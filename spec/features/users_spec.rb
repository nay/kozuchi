# -*- encoding : utf-8 -*-
require 'spec_helper'

describe UsersController do
  fixtures :users

  describe "GET /signup" do
    context "when not logged in" do
      before do
        visit '/signup'
      end
      it_behaves_like 'users/new'
    end
  end

  describe "ユーザー登録できる" do
    context "when not logged in" do
      before do
        visit "/"
        click_link "ユーザー登録"
        fill_in "ログインID", with: "featuretest"
        fill_in "Email", with: "featuretest@kozuchi.net"
        fill_in "パスワード", with: "testtest"
        fill_in "パスワード（確認）", with: "testtest"
        click_button "ユーザー登録"
      end

      it do
        expect(flash_notice).to have_content "登録が完了しました。"
        expect(page.current_path).to eq "/home"
      end


    end
  end
end
