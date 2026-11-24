require 'spec_helper'

describe Settings::FriendsController, type: :feature do
  fixtures :users, :accounts, :preferences

  describe "/settings/friends" do
    include_context "太郎 logged in"
    before do
      visit "/settings/friends"
    end
    it "登録フォームが表示されている" do
      expect(page).to have_css('form')
    end

    context "登録されていないユーザーIDを入力して登録したとき" do
      before do
        fill_in 'target_login', with: 'nobody'
        click_button 'フレンドを登録する（申し込む）'
      end
      it "見つからないことが表示される" do
        expect(page).to have_css('.alert-danger', text: '指定されたユーザーが見つかりません。')
      end
    end
  end
end
