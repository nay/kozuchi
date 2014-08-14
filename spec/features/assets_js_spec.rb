# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AssetsController, :js => true do
  self.use_transactional_fixtures = false
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  let(:target_date) {Date.today >> 1}
  before do
    Deal::Base.destroy_all
    select_menu('分析', '資産表')
  end

  describe "カレンダー（翌月）のクリック" do
    before do
      find("#month_#{target_date.year}_#{target_date.month} a").click
    end
    it do
      page.should have_content("#{target_date.year}年#{target_date.month}月末日の資産表")
    end
  end

  after(:each) do
    raise "not cleaned" if Deal::Base.first
  end

end
