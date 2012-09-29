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

end