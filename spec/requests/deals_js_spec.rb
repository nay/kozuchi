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

  describe "登録" do

    describe "通常明細" do
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

    describe "複数明細" do
      before do
        current_user.preferences.update_attribute(:uses_complex_deal, true)
        visit "/deals"
        click_link "明細(複数)"
      end

      describe "タブを表示できる" do
        it "タブが表示される" do
          page.should have_css('input#deal_summary')
          page.should have_css('input#deal_creditor_entries_attributes_0_reversed_amount')
          page.should have_css('input#deal_creditor_entries_attributes_1_reversed_amount')
          page.should have_css('input#deal_creditor_entries_attributes_2_reversed_amount')
          page.should have_css('input#deal_creditor_entries_attributes_3_reversed_amount')
          page.should have_css('input#deal_creditor_entries_attributes_4_reversed_amount')
          page.should have_css('select#deal_creditor_entries_attributes_0_account_id')
          page.should have_css('select#deal_creditor_entries_attributes_1_account_id')
          page.should have_css('select#deal_creditor_entries_attributes_2_account_id')
          page.should have_css('select#deal_creditor_entries_attributes_3_account_id')
          page.should have_css('select#deal_creditor_entries_attributes_4_account_id')
          page.should have_css('input#deal_debtor_entries_attributes_0_amount')
          page.should have_css('input#deal_debtor_entries_attributes_1_amount')
          page.should have_css('input#deal_debtor_entries_attributes_2_amount')
          page.should have_css('input#deal_debtor_entries_attributes_3_amount')
          page.should have_css('input#deal_debtor_entries_attributes_4_amount')
          page.should have_css('select#deal_debtor_entries_attributes_0_account_id')
          page.should have_css('select#deal_debtor_entries_attributes_1_account_id')
          page.should have_css('select#deal_debtor_entries_attributes_2_account_id')
          page.should have_css('select#deal_debtor_entries_attributes_3_account_id')
          page.should have_css('select#deal_debtor_entries_attributes_4_account_id')
        end
      end

      describe "記入欄を増やすことができる" do
        before do
          click_link '記入欄を増やす'
        end

        it "6つめの記入欄が表示される" do
          page.should have_css('input#deal_creditor_entries_attributes_5_reversed_amount')
          page.should have_css('select#deal_creditor_entries_attributes_5_account_id')
          page.should have_css('input#deal_debtor_entries_attributes_5_amount')
          page.should have_css('select#deal_debtor_entries_attributes_5_account_id')
        end
      end

      describe "1対2の明細が登録できる" do
        before do
          fill_in 'deal_summary', :with => '買い物'
          fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1000'
          select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '800'
          select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
          fill_in 'deal_debtor_entries_attributes_1_amount', :with => '200'
          select '雑費', :from => 'deal_debtor_entries_attributes_1_account_id'
          click_button '記入'
        end
        
        it "明細が一覧に表示される" do
          page.should have_content '追加しました。'
          page.should have_content '買い物'
          page.should have_content '1,000'
          page.should have_content '800'
          page.should have_content '200'
        end
      end

      after do
        current_user.preferences.update_attribute(:uses_complex_deal, false)
      end
    end

    describe "残高" do
      before do
        visit "/deals" # 今月へ。日付は入っているはず
        click_link "残高"
      end

      describe "タブを表示できる" do
        it do
          page.should have_css('select#deal_account_id')
          page.should have_content('計算')
          page.should have_content('残高:')
          page.should have_content('記入')

          page.should_not have_css('input#deal_summary')
        end
      end

      describe "パレットをつかって登録できる" do
        before do
          select '現金', :from => 'deal_account_id'
          fill_in 'gosen', :with => '1'
          fill_in 'jyu', :with => '3'
          click_button '計算'
          click_button '記入'
        end

        it "一覧に表示される" do
          page.should have_content("追加しました。")
          page.should have_content("残高確認")
          page.should have_content("5,030")
        end
      end
    end
  end

  describe "変更" do
    describe "通常明細" do
      before do
        FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン")
        visit "/deals/2012/7"
        click_link '変更'
      end

      describe "タブを表示できる" do
        it "変更タブが表示される" do
          page.should have_content("変更(2012-07-10-1)")
          find("input#deal_summary").value.should == "ラーメン"
        end
      end

      describe "実行できる" do
        before do
          fill_in 'date_day', :with => '11'
          fill_in 'deal_summary', :with => '冷やし中華'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '920'
          select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_0_account_id'
          click_button '変更'
        end

        it "一覧に表示される" do
          page.should have_content("更新しました。")
          page.should have_content("2012/07/11")
          page.should have_content('冷やし中華')
          page.should have_content('920')
          page.should have_content('クレジットカードＸ')
        end
      end
    end

    describe "複数明細" do
      before do
        current_user.preferences.update_attribute(:uses_complex_deal, true)
        FactoryGirl.create(:complex_deal, :date => Date.new(2012, 7, 7))
        visit "/deals/2012/7"
        click_link "変更"
      end

      describe "タブを表示できる" do
        it "タブが表示される" do
          page.should have_content("変更(2012-07-07-1)")
          find("input#deal_creditor_entries_attributes_0_reversed_amount").value.should == '1000'
          find("input#deal_debtor_entries_attributes_0_amount").value.should == '800'
          find("input#deal_debtor_entries_attributes_1_amount").value.should == '200'
        end
      end

      describe "変更ができる" do
        before do
          fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1200'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '900'
          fill_in 'deal_debtor_entries_attributes_1_amount', :with => '300'
          select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
          click_button '変更'
        end

        it "変更内容が一覧に表示される" do
          page.should have_content "更新しました。"
          page.should have_content '銀行'
          page.should have_content '1,200'
          page.should have_content '900'
          page.should have_content '300'
        end
      end

      describe "カンマ入りの数字を入れて口座を変えても変更ができる" do
        # reversed_amount の代入時にparseされていない不具合がたまたまこのスペックで発見できた
        before do
          fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1,200'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '900'
          fill_in 'deal_debtor_entries_attributes_1_amount', :with => '300'
          select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
          click_button '変更'
        end

        it "変更内容が一覧に表示される" do
          page.should have_content "更新しました。"
          page.should have_content '銀行'
          page.should have_content '1,200'
          page.should have_content '900'
          page.should have_content '300'
        end
      end
      
      after do
        current_user.preferences.update_attribute(:uses_complex_deal, false)
      end
    end

    describe "残高" do
      before do
        FactoryGirl.create(:balance_deal, :date => Date.new(2012, 7, 20), :balance => '2000')
        visit "/deals/2012/7"
        click_link '変更'
      end
      
      describe "タブを表示できる" do
        it "タブが表示される" do
          page.should have_content("変更(2012-07-20-1)")
          find("input#deal_balance").value.should == '2000'
        end
      end

      describe "実行できる" do
        before do
          fill_in 'deal_balance', :with => '2080'
          click_button '変更'
        end
        it "一覧に表示される" do
          page.should have_content("更新しました。")
          page.should have_content('2,080')
        end
      end
    end
  end

  describe "削除" do

    describe "通常明細" do
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

    describe "残高" do
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

end