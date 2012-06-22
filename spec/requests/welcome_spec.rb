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
  end

end
