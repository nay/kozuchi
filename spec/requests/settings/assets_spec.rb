# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Settings::AssetsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/settings/assets" do
    include_context "太郎 logged in"
    before do
      visit "/settings/assets"
    end
    it "口座名入力欄がある" do
      page.should have_css('input#account_name')
    end
  end
end