# -*- encoding : utf-8 -*-
require 'spec_helper'

describe SettlementsController, type: :feature do
  fixtures :users, :accounts, :account_links, :account_link_requests, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  describe "精算一覧" do
    let(:url) { '/settlements' }

    context "資産口座が現金しかないとき" do
      before do
        AccountLink.destroy_all
        AccountLinkRequest.destroy_all
        Account::Asset.where("asset_kind != 'cache'").delete_all # TODO: destroyできない
        visit url
      end

      it "精算機能が利用できないと表示される" do
        expect(page).to have_content("精算対象となる口座（債権、クレジットカード）が１つも登録されていないため、精算機能は利用できません。")
      end
    end

    context "資産口座にカードがあるとき" do
      # TODO: 精算データの有無で分けたい
      before do
        visit url
      end
      it "セルがある" do
        expect(page).to have_css("td.settlement")
      end
    end
  end
end
