require 'spec_helper'

describe "Settlements Features", type: :feature do
  fixtures :users, :accounts, :account_links, :account_link_requests, :preferences

  include_context "太郎 logged in"

  describe "すべての精算" do
    let(:url) { "/settlements/#{Time.zone.today.year}/#{Time.zone.today.month}" }

    before do
      visit url
    end

    it { expect(menu_bar).to eq "すべての精算" }
    it { expect(page.find('.book.settlements_summary')).to have_content "#{Time.zone.today.year}年" }
    it { expect(page.find('.book.settlements_summary')).to have_content "#{Time.zone.today.month}月" }
  end

  describe "精算（口座指定）" do
    let(:account) { accounts(:taro_card) }
    let(:url) { "/accounts/#{account.id}/settlements/#{Time.zone.today.year}/#{Time.zone.today.month}" }

    before do
      visit url
    end

    it { expect(menu_bar).to eq "#{account.name}の精算" }
    it { expect(page.find('.book.settlements_summary')).to have_content "#{Time.zone.today.year}年" }
    it { expect(page.find('.book.settlements_summary')).to have_content "#{Time.zone.today.month}月" }
  end
end
