# -*- encoding : utf-8 -*-
require 'spec_helper'

describe SettlementsController do
  fixtures :users, :accounts, :account_links, :account_link_requests, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  describe "新しい精算" do

    context "資産口座が現金しかないとき" do
      before do
        AccountLink.destroy_all
        AccountLinkRequest.destroy_all
        Account::Asset.destroy_all("asset_kind != 'cache'")
        visit '/settlements/new'
      end

      it "精算機能が利用できないと表示される" do
        page.should have_content("精算対象となる口座（債権、クレジットカード）が１つも登録されていないため、精算機能は利用できません。")
      end
    end

  end

end