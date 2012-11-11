# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.configure do |config|
  config.use_transactional_fixtures = false
end
describe Settings::AssetsController, :js => true do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"
  before do
    visit "/settings/assets"
  end

  describe "登録" do
    before do
      fill_in 'account_name', :with => 'VISAカード'
      select 'クレジットカード', :from => 'account_asset_kind'
      fill_in 'account_sort_key', :with => '10'
      click_button '新しい口座を追加'
    end

    it "登録が成功する" do
      page.should have_content("VISAカード」を登録しました。")
      account = current_user.accounts.find_by_name('VISAカード')
      account.should_not be_nil
      page.should have_css("input#account_#{account.id}_name")
    end

  end
end