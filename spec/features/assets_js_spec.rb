require 'spec_helper'

describe AssetsController, js: true, type: :feature do
  fixtures :users, :accounts, :preferences

  include_context "太郎 logged in"

  let(:target_date) {Time.zone.today >> 1}
  before do
    Deal::Base.destroy_all
    select_menu('分析', '資産表')
  end

  describe "カレンダー（翌月）のクリック" do
    before do
      click_calendar(target_date.year, target_date.month)
    end
    it do
      expect(page).to have_content("#{target_date.year}年#{target_date.month}月末日の資産表")
    end
  end

  after(:each) do
    raise "not cleaned" if Deal::Base.first
  end

end
