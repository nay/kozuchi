require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe DealsController do
  fixtures :users, :preferences, :accounts
  set_fixture_class :accounts => 'Account::Base', :preferences => 'Preferences'
  before do
    login_as :taro
  end
  describe "index" do
    it "monthlyにリダイレクトされる" do
      get :index
      response.should redirect_to monthly_deals_path(:year => Date.today.year, :month => Date.today.month)
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, :year => '2010', :month => '4'
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
      # 貸し方の金額ははいらない
      post :create_general_deal,
        :deal => {
          :date => {:year => '2010', :month => '7', :day => '7'},
          :summary => 'test',
          :creditor_entries_attributes => [{:account_id => :taro_cache.to_id}],
          :debtor_entries_attributes => [{:account_id => :taro_bank.to_id, :amount => 1000}]
        }
      response.should be_success
      deal = @current_user.general_deals.find_by_date_and_summary(Date.new(2010, 7, 7), 'test')
      deal.should_not be_nil
      deal.debtor_entries.size.should == 1
      deal.creditor_entries.size.should == 1
    end
  end
  describe "new_complex_deal" do
    it "成功する" do
      get :new_complex_deal
      response.should be_success
    end
  end
  describe "create_complex_deal" do
    it "成功する" do
      post :create_complex_deal,
        :deal => {
          :date => {:year => '2010', :month => '7', :day => '9'},
          :summary => 'test_complex',
          :creditor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => -800}, {:account_id => :taro_hanako.to_id, :amount => -200}],
          :debtor_entries_attributes => [{:account_id => :taro_bank.to_id, :amount => 1000}]
        }
      response.should be_success
      deal = @current_user.general_deals.find_by_date_and_summary(Date.new(2010, 7, 9), 'test_complex')
      deal.should_not be_nil
      deal.debtor_entries.size.should == 1
      deal.creditor_entries.size.should == 2
    end
  end
  describe "new_balance_deal" do
    it "成功する" do
      get :new_balance_deal
      response.should be_success
    end
  end
  describe "create_balance_deal" do
    it "成功する" do
      post :create_balance_deal, :account_id => :taro_cache.to_id, :deal => {
        :balance => 3000,
        :account_id => :taro_cache.to_id,
        :date => {:year => '2010', :month => '7', :day => '7'}
      }
      response.should be_success
      deal = @current_user.balance_deals.find_by_date(Date.new(2010, 7, 7))
      deal.should_not be_nil
      deal.balance.should == 3000
    end
  end

  describe "search" do
    it "成功する" do
      get :search, :keyword => 'test'
      response.should be_success
    end
    it "キーワードなしだとエラーとなる" do
      lambda{get :search}.should raise_error(InvalidParameterError)
    end
  end

  describe "destroy" do
    before do
      @deal = create_deal
    end
    it "成功する" do
      delete :destroy, :id => @deal.id
      response.should redirect_to(monthly_deals_path(:year => '2010', :month => '7'))
      Deal::Base.find_by_id(@deal.id).should be_nil
    end
  end

  describe "confirm" do
    before do
      @deal = create_deal(:confirmed => false)
    end
    it "成功する" do
      post :confirm, :id => @deal.id
      response.should redirect_to(monthly_deals_path(:year => '2010', :month => '7', :updated_deal_id => @deal.id))
      @deal.reload
      @deal.should be_confirmed
    end
  end

  describe "edit" do
    before do
      @deal = create_deal(:confirmed => false)
    end
    it "成功する" do
      get :edit, :id => @deal.id
      response.should be_success
    end
  end

  describe "update" do
    before do
      @deal = create_deal(:confirmed => false)
    end
    it "成功する" do
      put :update, :id => @deal.id, :deal => {
          :date => {:year => '2010', :month => '7', :day => '9'},
          :summary => 'changed like test_complex',
          :creditor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => -800}, '1' => {:account_id => :taro_hanako.to_id, :amount => -200}},
          :debtor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id, :amount => 1000}}
      }
      response.should be_success
      @deal.reload
      @deal.creditor_entries.size.should == 2
      @deal.summary.should == 'changed like test_complex'
      @deal.date.should == Date.new(2010, 7, 9)
    end
  end

  describe "create_entry" do
    context "新しいDealに対して" do
      it "成功する" do
        post :create_entry, :id => 'new', :deal => {
          :date => {:year => '2010', :month => '7', :day => '9'},
          :summary => 'changed like test_complex',
          :creditor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => -800}, '1' => {:account_id => :taro_hanako.to_id, :amount => -200}},
          :debtor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id, :amount => 1000}}
        }
        response.should be_success
      end
    end

    context "既存のDealに対して" do
      before do
        @deal = create_deal
      end
      it "成功する" do
        post :create_entry, :id => @deal.id, :deal => {
          :date => {:year => '2010', :month => '7', :day => '9'},
          :summary => 'changed like test_complex',
          :creditor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => -800}, '1' => {:account_id => :taro_hanako.to_id, :amount => -200}},
          :debtor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id, :amount => 1000}}
        }
        response.should be_success
      end
    end
  end


  private
  def create_deal(attributes = {})
    deal = @current_user.general_deals.build({:summary => 'in created_deal',
      :date => {:year => '2010', :month => '7', :day => '8'},
      :debtor_entries_attributes => [{:account_id => :taro_food.to_id, :amount => 500}],
      :creditor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => -500}]}.merge(attributes))
    deal.save!
    deal
  end

end