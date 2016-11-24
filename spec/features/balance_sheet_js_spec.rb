# -*- encoding : utf-8 -*-
require 'spec_helper'

describe BalanceSheetController, js: true, type: :feature do
  self.use_transactional_tests = false
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  let(:target_date) {Date.today >> 1}
  before do
    Deal::Base.destroy_all
    select_menu('分析', '貸借対照表')
  end

  describe "カレンダー（翌月）のクリック" do
    before do
      click_calendar(target_date.year, target_date.month)
    end
    it do
      expect(page).to have_content("#{target_date.year}年#{target_date.month}月末日の貸借対照表")
    end
  end

end