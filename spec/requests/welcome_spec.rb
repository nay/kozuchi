# -*- encoding : utf-8 -*-
require 'spec_helper'

describe WelcomeController do
  fixtures :users
  describe "GET /" do
    context "requested from pc" do
      context "when not logged in" do
        before do
          visit "/"
        end
        it {page.should have_content('Web家計簿 小槌')}
        it {page.should have_css("div#login_form")}
        it {page.should_not have_css("h1.mobile_title")}
      end

      context "when logged in" do
        include_context "太郎 logged in"

        before do
          visit "/"
        end
        it {page.should have_content('Web家計簿 小槌')}
        it {page.should_not have_css("div#login_form")}
      end
    end

    context "requested from AU without a passport" do
      include_context "requested from AU"
      context "when not logged in" do
        before do
          visit "/"
        end
        it {page.should have_content('Web家計簿 小槌')}
        it {page.should have_css("h1.mobile_title")}
        it {page.should have_css("div#login_form")}
        it {page.should_not have_content('ようこそ')}
      end
    end

    context "requested from AU with the passport" do
      include_context "requested from AU with the passport"
      before do
        visit "/"
      end
      it {page.should have_content('ようこそ')}
    end
  end

end
