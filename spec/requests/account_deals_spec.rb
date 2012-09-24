# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DealsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  describe "メニュー「口座別出納」のクリック" do
    before do
      visit 'accounts/deals'
    end

    it "最初の口座の今月の口座別出納が表示される" do
      page.should have_content("#{current_user.accounts.first.name}の出納一覧（#{Date.today.year}年#{Date.today.month}月）")
    end
  end

end