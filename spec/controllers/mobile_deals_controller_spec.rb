require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe MobileDealsController do
  fixtures :users, :accounts
  set_fixture_class :accounts => "Account::Base"
  before do
    login_as :taro
  end
  describe "daily_expenses" do
    it "成功する" do
      get :daily_expenses, :year => '2010', :month => '4', :day => '1'
      response.should be_success
    end
  end
  describe "daily_created" do
    it "成功する" do
      get :daily_created, :year => '2010', :month => '4', :day => '1'
      response.should be_success
    end
  end
  describe "new_general_deal" do
    it "成功する" do
      get :new_general_deal
      response.should be_success
    end
  end
  describe "create_general_deal" do
    it "成功する" do
      # creditor は金額は入っていかない
      post :create_general_deal, :deal => {
        :summary => 'from mobile',
        :date => {:year => '2010', :month => '8', :day => '14'},
        :debtor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => 300}},
        :creditor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id}}
      }
      response.should redirect_to(new_mobile_general_deal_path)
      deal = @current_user.deals.find_by_summary('from mobile')
      deal.should_not be_nil
      deal.date.should == Date.new(2010, 8, 14)
    end
  end
end
