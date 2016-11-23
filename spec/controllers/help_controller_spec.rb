# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe HelpController do
  fixtures :users
  context "ログインしているとき" do
    before do
      login_as :taro
    end
    describe "index" do
      it "成功する" do
        get :index
        response.should be_success
      end
    end
    describe "functions" do
      it "成功する" do
        get :functions
        response.should be_success
      end
    end
    describe "faq" do
      it "成功する" do
        get :faq
        response.should be_success
      end
    end
  end
  context "ログインしていないとき" do
    describe "index" do
      it "成功する" do
        get :index
        response.should be_success
      end
    end
    describe "functions" do
      it "成功する" do
        get :functions
        response.should be_success
      end
    end
    describe "faq" do
      it "成功する" do
        get :faq
        response.should be_success
      end
    end
  end
end