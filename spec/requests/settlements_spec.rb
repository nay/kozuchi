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

    context "資産口座にカードがあるとき" do

      context "対象記入がないとき" do
        before do
          visit '/settlements/new'
        end
        it "口座や期間のフォームがあり、データがない旨が表示される" do
          page.should have_css("select#settlement_account_id")
          page.should have_css("select#start_date_year")
          page.should have_css("select#end_date_day")
          page.should have_css("div#target_deals")
          page.should have_content("の未精算取引 は 全0件あります。")
        end
      end
    end

  end

end