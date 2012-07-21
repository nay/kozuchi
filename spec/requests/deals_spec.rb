# -*- encoding : utf-8 -*-
require 'spec_helper'

# TODO: とりあえずindex表示だけ仮に置いてみた。Ajax部分どうしようかな...
describe DealsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/deals/2012/7" do
    include_context "太郎 logged in"
    before do
      visit "/deals/2012/7"
    end
    it "明細表示領域がある" do
      page.should have_css('div#monthly_contents')
    end
    it "明細入力欄がある" do
      page.should have_css('input#deal_summary')
    end
  end
end