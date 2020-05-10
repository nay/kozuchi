require 'spec_helper'

describe "sesstings/assets", js: true, type: :feature do
  fixtures :users, :accounts, :preferences

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
      expect(page).to have_content("VISAカード」を登録しました。")
      account = current_user.accounts.find_by(name: 'VISAカード')
      expect(account).not_to be_nil
      expect(page).to have_css("input#account_#{account.id}_name")
    end

  end
end