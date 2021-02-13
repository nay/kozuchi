require 'spec_helper'

describe BalanceSheetController, type: :feature do
  fixtures :users, :accounts, :preferences

  include_context "太郎 logged in"

  before do
    visit 'balance_sheet'
  end

  describe "メニュー「貸借対照表」のクリック" do
    it "今月の貸借対照表が表示される" do
      expect(page).to have_content("#{Time.zone.today.year}年#{Time.zone.today.month}月末日の貸借対照表")
    end
  end

end