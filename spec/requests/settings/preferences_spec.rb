# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Settings::PreferencesController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/settings/preferences" do
    include_context "太郎 logged in"
    before do
      visit "/settings/preferences"
    end
    it "高さ指定欄がある" do
      page.should have_css('input#preferences_deals_scroll_height')
    end
  end
end