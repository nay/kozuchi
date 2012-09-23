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

  # 登録

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

    it "残高タブが表示される" do
      page.should have_content("追加しました。")
      page.should have_content("残高確認")
      page.should have_content("5,030")
    end
  end

  # 変更

  describe "通常明細の変更タブを表示できる" do
    before do
      FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン")
      visit "/deals/2012/7"
      click_link '変更'
    end

    it "変更タブが表示される" do
      page.should have_content("変更(2012-07-10-1)")
      find("input#deal_summary").value.should == "ラーメン"
    end
  end

  describe "通常明細を変更できる" do
    before do
      FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン")
      visit "/deals/2012/7"
      click_link '変更'
      fill_in 'date_day', :with => '11'
      fill_in 'deal_summary', :with => '冷やし中華'
      fill_in 'deal_debtor_entries_attributes_0_amount', :with => '920'
      select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_0_account_id'
      click_button '変更'
    end

    it "変更された記入が表示される" do
      page.should have_content("更新しました。")
      page.should have_content("2012/07/11")
      page.should have_content('冷やし中華')
      page.should have_content('920')
      page.should have_content('クレジットカードＸ')
    end
  end


  # 削除

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