require 'spec_helper'

describe ProfitAndLossController, type: :feature do
  fixtures :users, :accounts, :preferences

  include_context "太郎 logged in"

  before do
    visit 'profit_and_loss'
  end

  describe "メニュー「収支表」のクリック" do
    it "今月の収支表が表示される" do
      expect(page).to have_content("#{Time.zone.today.year}年#{Time.zone.today.month}月末日の収支表")
    end
  end

end