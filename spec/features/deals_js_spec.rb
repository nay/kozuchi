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

  describe "今日エリアのクリック" do
    let(:target_date) {Date.today << 1}
    before do
      # 前月にしておいて
      find('#header_menu').click_link '家計簿'
      find("#month_#{target_date.year}_#{target_date.month}").click_link "#{target_date.month}月"

      # クリック
      find("#user_and_today").click
    end

    it "カレンダーの選択月が今月に変わり、今日の日付が入る" do
      find("td.selected_month").text.should == "#{Date.today.month}月"
      find("input#date_day").value.should == Date.today.day.to_s
    end

  end

  describe "カレンダー（翌月）のクリック" do
    let(:target_date) {Date.today >> 1}
    before do
      find('#header_menu').click_link '家計簿'
      find("#month_#{target_date.year}_#{target_date.month}").click_link "#{target_date.month}月"
    end

    it "カレンダーの選択月が翌月に変わる" do
      find("td.selected_month").text.should == "#{target_date.month}月"
    end
  end

  describe "カレンダー（翌年）のクリック" do
    before do
      find('#header_menu').click_link '家計簿'
      find("#next_year").click
    end

    it "翌年が入力された状態になる" do
      find("input#date_year").value.should == (Date.today >> 12).year.to_s
    end
  end

  describe "カレンダー（前年）のクリック" do
    before do
      find('#header_menu').click_link '家計簿'
      find("#prev_year").click
    end

    it "前年が入力された状態になる" do
      find("input#date_year").value.should == (Date.today << 12).year.to_s
    end
  end

  describe "日ナビゲーターのクリック" do
    let(:target_date) {Date.today << 1} # 前月
    before do
      find('#header_menu').click_link '家計簿'
      find("#month_#{target_date.year}_#{target_date.month}").click_link "#{target_date.month}月"
      # 3日をクリック
      date = Date.new((Date.today << 1).year, target_date.month, 3)
      click_link I18n.l(date, :format => :day).strip # strip しないとマッチしない
    end

    it "URLに対応する日付ハッシュがつき、日の欄に指定した日が入る" do
      current_url =~ (/^.*#(.*)$/)
      $1.should == 'day3'
      find("input#date_day").value.should == '3'
    end
  end

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
        flash_notice.should have_content('追加しました。')
        page.should have_content('朝食のおにぎり')
      end

    end

    describe "通常明細のサジェッション" do
      describe "'のない明細" do
        before do
          FactoryGirl.create(:general_deal, :date => Date.today, :summary => "朝食のサンドイッチ")
          visit "/deals" # 今月へ。日付は入っているはず

          fill_in 'deal_summary', :with => '朝食'
          sleep 0.6
        end
        it "先に登録したデータがサジェッション表示される" do
          page.should have_css("#patterns div.clickable_text")
        end
        it "サジェッションをクリックするとデータが入る" do
          page.find("#patterns div.clickable_text").click
          page.find("#deal_summary").value.should == '朝食のサンドイッチ'
        end
      end

      describe "'のある明細" do
        before do
          FactoryGirl.create(:general_deal, :date => Date.today, :summary => "朝食の'サンドイッチ'")
          visit "/deals" # 今月へ。日付は入っているはず

          fill_in 'deal_summary', :with => '朝食'
          sleep 0.6
        end
        it "先に登録したデータがサジェッション表示される" do
          page.should have_css("#patterns div.clickable_text")
        end
        it "サジェッションをクリックするとデータが入る" do
          page.find("#patterns div.clickable_text").click
          page.find("#deal_summary").value.should == "朝食の'サンドイッチ'"
        end
      end
    end

    describe "複数明細" do
      before do
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
          find('a.entry_summary').click # unifyモードにする
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
          flash_notice.should have_content('追加しました。')
          page.should have_content '買い物'
          page.should have_content '1,000'
          page.should have_content '800'
          page.should have_content '200'
        end
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
          flash_notice.should have_content("追加しました。")
          page.should have_content("残高確認")
          page.should have_content("5,030")
        end
      end
    end
  end

  describe "変更" do
    describe "複数明細利用時" do
      before do
        FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン")
        visit "/deals/2012/7"
        click_link '変更'
      end
      it "変更タブが表示される" do
        tab_window.should have_content("変更(2012-07-10-1)")
        find("input#deal_summary").value.should == "ラーメン"
      end

      describe "複数記入への変更" do
        before do
          click_link '複数記入にする'
        end
        it "フォーム部分だけが変わる" do
          page.should have_content("仕訳帳")
          page.should have_css("select#deal_creditor_entries_attributes_4_account_id")
        end
        it "記入欄を増やせる" do
          click_link '記入欄を増やす'
          page.should have_css("select#deal_creditor_entries_attributes_5_account_id")
        end
      end
    end

    describe "通常明細" do
      before do
        FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン")
        visit "/deals/2012/7"
        click_link '変更'
      end

      describe "タブを表示できる" do
        it "変更タブが表示される" do
          tab_window.should have_content("変更(2012-07-10-1)")
          find("input#deal_summary").value.should == "ラーメン"
        end
      end

      describe "実行できる" do
        before do
          find("#date_day[value='10']")
          fill_in 'date_day', :with => '11'
          fill_in 'deal_summary', :with => '冷やし中華'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '920'
          select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_0_account_id'
          click_button '変更'
        end

        it "一覧に表示される" do
          flash_notice.should have_content("更新しました。")
          flash_notice.should have_content("2012/07/11")
          page.should have_content('冷やし中華')
          page.should have_content('920')
          page.should have_content('クレジットカードＸ')
        end
      end
    end

    describe "複数明細" do
      before do
        FactoryGirl.create(:complex_deal, :date => Date.new(2012, 7, 7))
        visit "/deals/2012/7"
        click_link "変更"
      end

      describe "タブを表示できる" do
        it "タブが表示される" do
          tab_window.should have_content("変更(2012-07-07-1)")
          find("input#deal_creditor_entries_attributes_0_reversed_amount").value.should == '1000'
          find("input#deal_debtor_entries_attributes_0_amount").value.should == '800'
          find("input#deal_debtor_entries_attributes_1_amount").value.should == '200'
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

      describe "変更ができる" do
        before do
          fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1200'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '900'
          fill_in 'deal_debtor_entries_attributes_1_amount', :with => '300'
          select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
          click_button '変更'
        end

        it "変更内容が一覧に表示される" do
          flash_notice.should have_content "更新しました。"
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
          flash_notice.should have_content "更新しました。"
          page.should have_content '銀行'
          page.should have_content '1,200'
          page.should have_content '900'
          page.should have_content '300'
        end
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
          tab_window.should have_content("変更(2012-07-20-1)")
          find("input#deal_balance").value.should == '2000'
        end
      end

      describe "実行できる" do
        before do
          fill_in 'deal_balance', :with => '2080'
          click_button '変更'
        end
        it "一覧に表示される" do
          flash_notice.should have_content("更新しました。")
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
        flash_notice.should have_content("削除しました。")
      end
    end

    describe "複数明細" do
      before do
        FactoryGirl.create(:complex_deal, :date => Date.new(2012, 7, 7))
        visit "/deals/2012/7"
        click_link "削除"
        page.driver.browser.switch_to.alert.accept
      end

      it do
        flash_notice.should have_content("削除しました。")
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
        flash_notice.should have_content("削除しました。")
      end
    end

  end

end