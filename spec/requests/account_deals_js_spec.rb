# -*- encoding : utf-8 -*-
require 'spec_helper'
RSpec.configure do |config|
  config.use_transactional_fixtures = false
end

describe AccountDealsController, :js => true do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  before do
    Deal::Base.destroy_all
    click_link '家計簿'
    click_link '口座別出納'
  end

  describe "カレンダー（翌月）のクリック" do
    let(:target_month) {(Date.today >> 1).month}
    before do
      click_link("#{target_month}月")
    end
    it do
      page.should have_content("#{current_user.accounts.first.name}の出納一覧（#{Date.today.year}年#{target_month}月）")
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
        page.should have_content('追加しました。')
        page.should have_content('ランチ そば')
      end
    end

  end

end