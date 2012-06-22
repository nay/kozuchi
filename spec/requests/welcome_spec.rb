# -*- encoding : utf-8 -*-
require 'spec_helper'

describe WelcomeController do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  shared_examples "index for pc" do
    it {page.should have_content('Web家計簿 小槌')}
    it {page.should_not have_css("h1.mobile_title")}
  end

  shared_examples "index for mobile" do
    it {page.should have_content('Web家計簿 小槌')}
    it {page.should have_css("h1.mobile_title")}
  end

  shared_examples "having login form" do
    it {page.should have_css("div#login_form")}
  end
  
  shared_examples "not having login form" do
    it {page.should_not have_css("div#login_form")}
  end

  shared_examples "having welcome message" do
    it {page.should have_content('ようこそ')}
  end

  shared_examples "not having welcome message" do
    it {page.should_not have_content('ようこそ')}
  end

  describe "GET /" do
    context "requested from pc" do
      context "when not logged in" do
        before do
          visit "/"
        end
        it_behaves_like "index for pc"
        it_behaves_like "having login form"
      end

      context "when logged in" do
        include_context "太郎 logged in"

        before do
          visit "/"
        end
        it_behaves_like "index for pc"
        it_behaves_like "not having login form"
      end
    end

    context "requested from AU" do
      include_context "requested from AU"
      context "without a passport" do
        context "when not logged in" do
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "having login form"
          it_behaves_like "not having welcome message"
        end

        context "when logged in" do
          include_context "no_mobile_ident_user logged in"
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "not having login form"
          it_behaves_like "having welcome message"
        end
      end

      context "with the passport" do
        include_context "with the passport for AU"
        before do
          visit "/"
        end
        it_behaves_like "index for mobile"
        it_behaves_like "not having login form"
        it_behaves_like "having welcome message"
      end
    end

    context "requested from DoCoMo" do
      include_context "requested from DoCoMo"
      context "without a passport" do
        context "when not logged in" do
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "having login form"
          it_behaves_like "not having welcome message"
        end

        context "when logged in" do
          include_context "no_mobile_ident_user logged in"
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "not having login form"
          it_behaves_like "having welcome message"
        end
      end

      context "with the passport" do
        include_context "with the passport for DoCoMo"
        before do
          visit "/"
        end
        it_behaves_like "index for mobile"
        it_behaves_like "not having login form"
        it_behaves_like "having welcome message"
      end
    end

  end

end
