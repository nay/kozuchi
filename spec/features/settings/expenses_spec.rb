require 'spec_helper'

describe Settings::AccountsController, type: :feature do
  fixtures :users, :accounts, :preferences

  describe "/settings/expenses" do
    include_context "太郎 logged in"
    before do
      visit "/settings/expenses"
    end
    it "口座名入力欄がある" do
      expect(page).to have_css('input#account_name')
    end
    it "各口座のフォームがある" do
      expect(page).to have_css('table.accounts')
    end
  end
end