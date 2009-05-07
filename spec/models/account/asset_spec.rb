require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Account::Asset" do
  fixtures :users
  before do
    @user = users(:taro)
    @capital_fund = @user.assets.create!(:name => "資本金", :asset_kind => "capital_fund")
    @credit_card = @user.assets.create!(:name => "クレジットカード", :asset_kind => "credit_card")
  end
  describe "capital_fund?" do
    it "資本金口座でtrueになること" do
      @capital_fund.capital_fund?.should be_true
    end
    it "クレジットカード口座でfalseになること" do
      @credit_card.capital_fund?.should be_false
    end
  end
  describe "credit_card?" do
    it "資本金口座でfalseになること" do
      @capital_fund.credit_card?.should be_false
    end
    it "クレジットカード口座でtrueになること" do
      @credit_card.credit_card?.should be_true
    end
  end

  describe "to_xml" do
    describe "idを指定しないとき" do
      before do
        raise "no @credit_card" unless @credit_card
        @xml = @credit_card.to_xml(:camelize => true, :skip_types => true, :only => [:name])
      end
      it "XMLにtypeが含まれること" do
        @xml.should =~ /type="asset"/
      end
      it "XMLにasset_kindが含まれること" do
        @xml.should =~ /asset_kind="credit_card"/
      end
      it "XMLにidが含まれないこと" do
        @xml.should_not =~ /id=/
      end
    end
    describe "idを指定したとき" do
      before do
        raise "no @credit_card" unless @credit_card
        @credit_card.serialized_id = 33
        @xml = @credit_card.to_xml(:camelize => true, :skip_types => true, :only => [:name])
      end
      it "XMLにidが含まれること" do
        @xml.should =~ /id="account33"/
      end
    end
  end

end
