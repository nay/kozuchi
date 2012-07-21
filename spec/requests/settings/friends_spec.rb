# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Settings::FriendsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/settings/friends" do
    include_context "太郎 logged in"
    before do
      visit "/settings/friends"
    end
    it "" do
      page.should have_css('div#page')
    end
  end
end
