# -*- encoding : utf-8 -*-
require 'spec_helper'

describe BalanceSheetController, type: :feature do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  before do
    visit 'balance_sheet'
  end

  describe "メニュー「貸借対照表」のクリック" do
    it "今月の貸借対照表が表示される" do
      expect(page).to have_content("#{Date.today.year}年#{Date.today.month}月末日の貸借対照表")
    end
  end

end