require 'spec_helper'

describe Settings::PreferencesController, type: :feature do
  fixtures :users, :accounts, :preferences

  describe "/settings/preferences" do
    include_context "太郎 logged in"
    before do
      visit "/settings/preferences"
    end
    it "色の欄がある" do
      expect(page).to have_css('input#preferences_color')
    end
  end
end