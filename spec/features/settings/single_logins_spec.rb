# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Settings::SingleLoginsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/settings/single_logins" do
    include_context "太郎 logged in"
    before do
      visit "/settings/single_logins"
    end
    it "ログイン名入力欄がある" do
      page.should have_css('input#single_login_login')
    end
  end
end