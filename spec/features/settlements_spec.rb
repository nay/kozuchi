# -*- encoding : utf-8 -*-
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
  end
end
