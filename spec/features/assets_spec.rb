require 'spec_helper'

describe AssetsController, type: :feature do
  fixtures :users, :accounts, :preferences

  include_context "太郎 logged in"

  before do
    visit '/f/assets'
  end

  describe "メニュー「資産表」のクリック" do
    it "今月の資産表が表示される" do
      expect(page).to have_content("#{Time.zone.today.year}年#{Time.zone.today.month}月末日の資産表")
    end
  end

end