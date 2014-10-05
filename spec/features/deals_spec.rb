# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DealsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  # 一覧
  describe "/deals/2012/7" do
    include_context "太郎 logged in"
    context "with no deals" do
      before do
        visit "/deals/2012/7"
      end
      it "明細表示領域がある" do
        page.should have_css('div#monthly_contents')
      end
      it "日ナビゲーターがある" do
        page.should have_css('#day_navigator')
      end
    end

    context "with one balance deal" do
      before do
        FactoryGirl.create(:balance_deal, :date => Date.new(2012, 7, 20))
        visit "/deals/2012/7"
      end
      it do
        page.should have_content("2012/07/20")
      end
    end
  end

  # 検索
  describe "/deals/search" do
    include_context "太郎 logged in"
    before do
      visit "/deals/2012/7"
    end

    context "when no deal with the keyword exists" do
      before do
        fill_in 'keyword', :with => 'test'
        click_button('検索')
      end
      it do
        page.should have_content("「test」を含む明細は登録されていません。")
      end
    end

    context "when one deal with the keyword exists" do
      before do
        @deal = FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10))
        fill_in 'keyword', :with => 'ランチ'
        click_button('検索')
      end
      it do
        page.should have_content("「ランチ」を含む明細は1件あります。")
      end
    end
  end

end