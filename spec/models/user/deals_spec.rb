require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../deals_spec_helper')
include DealsSpecHelper

describe "user.deals" do
  fixtures :users, :accounts

  describe "created_on" do
    before do
      @deal = new_deal(2009, 12, 6, :taro_cache => -100, :taro_food => 100)
      @deal.save!
    end
    it "成功すること" do
      expect(users(:taro).deals.created_on(Time.zone.today).include?(@deal)).to be_truthy
    end
  end

  describe "empty?" do
    it "成功すること" do
      expect{ users(:taro).deals.empty? }.not_to raise_error
    end
  end
  
end
