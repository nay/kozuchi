# -*- encoding : utf-8 -*-
require 'spec_helper'

describe MobileDealsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/mobile/deals/general/new" do
    include_context "requested from AU"
    include_context "no_mobile_ident_user logged in"
    before do
      visit "/mobile/deals/general/new"
    end
    it "明細入力欄がある" do
      page.should have_css('input#deal_summary')
    end
  end
end