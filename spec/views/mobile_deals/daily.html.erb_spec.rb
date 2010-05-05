require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../deals_spec_helper')
include DealsSpecHelper

describe "/mobile_deals/daily_created" do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  before(:each) do
    login_as :taro
    @current_user = users(:taro)
    @date = Date.new(2009, 12, 6)
    assigns[:date] = @date
  end

  describe "@dealsが空のとき" do
    before do
      assigns[:deals] = []
      render '/mobile_deals/daily_created'
    end
    it "成功すること" do
      response.should be_success
    end
  end

  describe "@dealsに通常記入が１つあるとき" do
    before do
      deal = new_deal(@date.year, @date.month, @date.day, :taro_cache => -100, :taro_food => 100)
      deal.save!
      assigns[:deals] = [deal]
      render '/mobile_deals/daily_created'
    end
    it "成功すること" do
      response.should be_success
    end
  end

end
