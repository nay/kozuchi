require 'spec_helper'

describe "シングルログインでの切り替え", type: :feature do
  fixtures :users, :accounts, :preferences, :friend_requests, :friend_permissions

  include_context "太郎 logged in"

  context "taroさんがhanakoさんに切り替えているとき" do
    before do
      current_user.single_logins.create!(login: 'hanako', password: 'hanako')
      visit home_path
      click_button 'taroさんでログイン中'
      click_link 'hanakoさんのアカウントへ移動'
    end

    it "メニューに、アカウントそのものに関わる項目が出ない" do
      within('body header .navbar') do
        expect(page).to have_link('口座')
        expect(page).not_to have_link('プロフィール')
        expect(page).not_to have_link('フレンド')
        expect(page).not_to have_link('シングルログイン')
      end
    end

    it "プロフィールの画面を開くと、ホームに戻され、操作できないことが表示される" do
      visit edit_user_path
      expect(page).to have_current_path(home_path)
      expect(page).to have_css('.alert-danger', text: 'hanakoさんに切り替えているあいだは操作できません。taroさんのアカウントに戻ってから操作してください。')
    end
  end
end
