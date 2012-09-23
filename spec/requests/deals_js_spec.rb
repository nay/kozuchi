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

  describe "残高明細の削除" do
    before do
      FactoryGirl.create(:balance_deal, :date => Date.new(2012, 7, 20))
    end
    include_context "太郎 logged in"
    context "target is a balance deal" do
      before do
        visit "/deals/2012/7"
        click_link('削除')
        page.driver.browser.switch_to.alert.accept
      end
      it do
        page.should have_content("削除しました。")
      end
    end
  end
end