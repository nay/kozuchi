require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../deals_spec_helper')
include DealsSpecHelper

describe "user.deals" do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  describe "created_on" do
    before do
      @deal = new_deal(2009, 12, 6, :taro_cache => -100, :taro_food => 100)
      @deal.save!
    end
    it "成功すること" do
      users(:taro).deals.created_on(Date.today).include?(@deal).should be_true
    end
  end

  describe "empty?" do
    it "成功すること" do
      lambda {users(:taro).deals.empty?}.should_not raise_error
    end
  end
  
end
