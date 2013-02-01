# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AccountDealsController, :js => true do
  self.use_transactional_fixtures = false
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  before do
    Deal::Base.destroy_all
    find('#header_menu').click_link '家計簿'
    click_link '口座別出納'
  end

  describe "カレンダー（翌月）のクリック" do
    let(:target_date) {Date.today >> 1}
    before do
      find("#month_#{target_date.year}_#{target_date.month}").click_link("#{target_date.month}月")
    end
    it do
      page.should have_content("#{current_user.accounts.first.name}の出納一覧（#{target_date.year}年#{target_date.month}月）")
    end
  end

  describe "カレンダー（翌年）のクリック" do
    before do
      find("#next_year").click
    end

    it "翌年が入力された状態になる" do
      find("input#date_year").value.should == (Date.today >> 12).year.to_s
    end
  end

  describe "カレンダー（前年）のクリック" do
    before do
      find("#prev_year").click
    end

    it "前年が入力された状態になる" do
      find("input#date_year").value.should == (Date.today << 12).year.to_s
    end
  end

  describe "日ナビゲーターのクリック" do
    let(:target_date) {Date.today << 1} # 前月
    before do
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
    describe "出金" do
      before do
        select '現金', :from => 'account_id'
        fill_in 'deal_summary', :with => 'ランチ そば'
        fill_in 'deal_debtor_entries_attributes_0_amount', :with => '720'
        select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
        click_button '記入'
      end
      it '一覧に表示される' do
        flash_notice.should have_content('追加しました。')
        page.should have_content('ランチ そば')
      end
    end

    describe "入金" do
      before do
        click_link '入金'
      end

      it "タブが表示される" do
        page.should have_css('input#deal_summary')
        page.should have_css('select#deal_creditor_entries_attributes_0_account_id')
      end

      describe "記入を追加したとき" do
        before do
          select '現金', :from => 'account_id'
          fill_in 'deal_summary', :with => 'おろした'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '20000'
          select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
          click_button '記入'
        end
        it "一覧に表示される" do
          flash_notice.should have_content('追加しました。')
          page.should have_content('おろした')
        end
      end
    end

    describe "残高" do
      before do
        click_link '残高'
      end

      it "タブが表示される" do
        page.should have_css('input#deal_balance')
      end

      describe "残高を記入したとき" do
        before do
          select '現金', :from => 'account_id'
          fill_in 'deal_balance', :with => '1200'
          click_button '記入'
        end
        it "一覧に表示される" do
          flash_notice.should have_content('追加しました。')
          page.should have_content('残高確認')
          page.should have_content('1,200')
        end
      end
    end

  end

  describe "移動" do
    describe "記入" do
      before do
        FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10))
        visit "/accounts/#{Fixtures.identify(:taro_cache)}/deals/2012/7"
        click_link '→'
      end
      it do
        page.should have_css('tr.updated_line')
      end
    end
  end

end