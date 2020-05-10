require 'spec_helper'

describe Settings::PartnerAccountsController, type: :feature do
  fixtures :users, :accounts, :preferences

  describe "/settings/accounts/partners" do
    include_context "太郎 logged in"
    before do
      visit "/settings/accounts/partners"
    end
    it "口座名選択欄がある" do
      expect(page).to have_css('select#account_partner_account_id')
    end
  end
end