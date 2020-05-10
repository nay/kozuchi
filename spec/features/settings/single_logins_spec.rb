require 'spec_helper'

describe Settings::SingleLoginsController, type: :feature do
  fixtures :users, :accounts, :preferences

  describe "/settings/single_logins" do
    include_context "太郎 logged in"
    before do
      visit "/settings/single_logins"
    end
    it "ログイン名入力欄がある" do
      expect(page).to have_css('input#single_login_login')
    end

    describe "新しい設定の登録" do
      before do
        fill_in 'single_login_login', :with => login
        fill_in 'single_login_password', :with => password
        click_button '新しい設定を登録'
      end
      context "パスワードが正しいとき" do
        let(:login) { 'hanako' }
        let(:password) { 'hanako' }
        it "追加メッセージが出て、ログイン名入力欄がある" do
          expect(flash_notice).to have_content('追加しました')
          expect(page).to have_css('input#single_login_login')
        end
      end
      context "パスワードが異なるとき" do
        let(:login) { 'hanako' }
        let(:password) { 'wrong' }
        it "追加メッセージ欄がなく、ログイン名入力欄がある" do
          expect(page).not_to have_css('#notice')
          expect(page).to have_css('input#single_login_login')
        end
      end
    end
  end

end