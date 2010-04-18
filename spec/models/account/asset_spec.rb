require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Account::Asset" do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base
  
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
      it "要素名が型にちなんでいること" do
        @xml.should =~ /<asset.*>.*<\/asset>/
      end
      it "XMLにasset_kindが含まれること" do
        @xml.should =~ /type="credit_card"/
      end
      it "XMLにidが含まれること" do
        @xml.should =~ /id="account/
      end
    end
  end

  describe "to_csv" do
    before do
      raise "no @credit_card" unless @credit_card
      @csv = @credit_card.to_csv
    end
    it "想定の形であること" do
      @csv.should == "asset,#{@credit_card.id},credit_card,#{@credit_card.sort_key},\"クレジットカード\""
    end
  end

  describe "balance_before" do
    before do
      @year = 2009
      @current_user = users(:taro)
      @cache = accounts(:taro_cache)
    end
    it "記入が１つもないとき0であること" do
      @cache.balance_before(Date.new(2009, 4, 1)).should == 0
    end
    describe "残高記入がシステム内になく、4/1に400円の食費を払った記入だけがある場合" do
      before do
        create_deal :taro_cache, :taro_food, 400, 4, 1
      end
      it "4/2より前の残高は-400であること" do
        @cache.balance_before(Date.new(2009, 4, 2)).should == -400
      end
      it "4/1より前の残高は0であること" do
        @cache.balance_before(Date.new(2009, 4, 1)).should == 0
      end
    end
    describe "4/1に400円の食費を払い、4/2に残高3000円を記入した場合" do
      before do
        create_deal :taro_cache, :taro_food, 400, 4, 1
        create_balance :taro_cache, 3000, 4, 2
      end
      it "4/3より前の残高は3000であること" do
        @cache.balance_before(Date.new(2009, 4, 3)).should == 3000
      end
      it "4/1より前の残高は3400であること" do
        @cache.balance_before(Date.new(2009, 4, 1)).should == 3400
      end

    end
#  def balance_before(date, daily_seq = 0, ignore_initial = false) do
  end


  # 現金→食費の取引記入をする
  def create_deal(from, to, amount, month, day, attributes = {})
    attributes = {:summary => "#{month}/#{day}の買い物",
      :debtor_entries_attributes => [{:account_id => Fixtures.identify(to), :amount => amount}],
      :creditor_entries_attributes => [{:account_id => Fixtures.identify(from), :amount => amount.to_i * -1}],
#      :amount => amount,
#      :minus_account_id => Fixtures.identify(from),
#      :plus_account_id => Fixtures.identify(to),
      :user_id => @current_user.id, :date => Date.new(@year, month, day)}.merge(attributes)
    Deal::General.create!(attributes)
  end

  # 現金の残高記入をする
  def create_balance(account_fixture_name, balance, month, day)
    Deal::Balance.create!(:summary => "", :balance => balance, :account_id => Fixtures.identify(account_fixture_name), :user_id => @user.id, :date => Date.new(@year, month, day))
  end

end
