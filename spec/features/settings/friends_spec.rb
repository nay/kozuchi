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
  end
end
