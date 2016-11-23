# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe AssetsController do
  fixtures :users, :accounts
  set_fixture_class :accounts => Account::Base
  before do
    login_as :taro
  end
  describe "index" do
    context "口座が十分あるとき" do
      it "monthlyにリダイレクトされる" do
        get :index
        response.should redirect_to(monthly_assets_path(:year => Date.today.year, :month => Date.today.month))
      end
    end
    context "口座がないとき" do
      before do
        @current_user.accounts.destroy_all
      end
      it "エラーページが表示される" do
        get :index
        response.should be_success
      end
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, {:year => Date.today.year.to_s, :month => Date.today.month.to_s}
      response.should be_success
    end
  end
end