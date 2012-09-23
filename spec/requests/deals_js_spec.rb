# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.configure do |config|
  config.use_transactional_fixtures = false
end

describe DealsController, :js => true do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  before do
    Deal::Base.delete_all
  end

  include_context "太郎 logged in"

  describe "通常明細を削除できる" do
    before do
      FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10))
      visit "/deals/2012/7"
      click_link('削除')
      page.driver.browser.switch_to.alert.accept
    end
    it do
      page.should have_content("削除しました。")
    end
  end

  describe "残高明細を削除できる" do
    before do
      FactoryGirl.create(:balance_deal, :date => Date.new(2012, 7, 20))
      visit "/deals/2012/7"
      click_link('削除')
      page.driver.browser.switch_to.alert.accept
    end
    it do
      page.should have_content("削除しました。")
    end
  end
end