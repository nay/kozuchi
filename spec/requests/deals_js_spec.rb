# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.configure do |config|
  config.use_transactional_fixtures = false
end

describe DealsController, :js => true do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  before do
    Deal::Base.destroy_all
  end

  include_context "太郎 logged in"

  describe "通常明細を登録できる" do
    before do
      visit "/deals" # 今月へ。日付は入っているはず
      fill_in 'deal_summary', :with => '朝食のおにぎり'
      fill_in 'deal_debtor_entries_attributes_0_amount', :with => '210'
      select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
      select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
      click_button '記入'
    end

    it do
      page.should have_content('追加しました。')
      page.should have_content('朝食のおにぎり')
    end
  end

  describe "残高記入のタブを表示できる" do
    before do
      visit "/deals" # 今月へ。日付は入っているはず
      click_link "残高"
    end

    it do
      page.should have_css('select#deal_account_id')
      page.should have_content('計算')
      page.should have_content('残高:')
      page.should have_content('記入')

      page.should_not have_css('input#deal_summary')
    end
  end
  
  describe "残高をパレットをつかって登録できる" do
    before do
      visit "/deals" # 今月へ。日付は入っているはず
      click_link "残高"
      select '現金', :from => 'deal_account_id'
      fill_in 'gosen', :with => '1'
      fill_in 'jyu', :with => '3'
      click_button '計算'
      click_button '記入'
    end

    it do
      page.should have_content("追加しました。")
      page.should have_content("残高確認")
      page.should have_content("5,030")
    end

  end

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