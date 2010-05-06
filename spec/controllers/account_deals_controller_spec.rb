require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../mobile_spec_helper')

describe AccountDealsController do
  fixtures :users, :preferences, :friend_requests, :friend_permissions, :accounts, :account_links, :account_link_requests
  set_fixture_class :accounts => 'Account::Base', :preferences => 'Preferences'

  before do
    login_as :taro
  end

  describe "new_creditor_general_deal" do
    it "成功する" do
      get :new_creditor_general_deal, :account_id => :taro_cache.to_id
      response.should be_success
    end
  end
  describe "create_creditor_general_deal" do
    it "成功する" do
      # cacheからの 出金
      post :create_creditor_general_deal, :account_id => :taro_cache.to_id,
        :deal => {
          :date => {:year => '2010', :month => '7', :day => '7'},
          :summary => 'test',
          :creditor_entries_attributes => [{:account_id => :taro_cache.to_id}],
          :debtor_entries_attributes => [{:account_id => :taro_food.to_id, :amount => 1000}]
        }
      response.should be_success
      deal = @current_user.general_deals.find_by_date_and_summary(Date.new(2010, 7, 7), 'test')
      deal.should_not be_nil
      deal.debtor_entries.size.should == 1
      deal.creditor_entries.size.should == 1
    end
  end

  describe "new_debtor_general_deal" do
    it "成功する" do
      get :new_debtor_general_deal, :account_id => :taro_cache.to_id
      response.should be_success
    end
  end
  describe "create_debtor_general_deal" do
    it "成功する" do
      # cacheへの入金
      post :create_debtor_general_deal, :account_id => :taro_cache.to_id,
        :deal => {
          :date => {:year => '2010', :month => '7', :day => '7'},
          :summary => 'test',
          :debtor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => 1000}],
          :creditor_entries_attributes => [{:account_id => :taro_bank.to_id}]
        }
      response.should be_success
      deal = @current_user.general_deals.find_by_date_and_summary(Date.new(2010, 7, 7), 'test')
      deal.should_not be_nil
      deal.debtor_entries.size.should == 1
      deal.creditor_entries.size.should == 1
    end
  end

  describe "new_balance_deal" do
    it "成功する" do
      get :new_balance_deal, :account_id => :taro_cache.to_id
      response.should be_success
    end
  end
  
  describe "create_balance_deal" do
    it "成功する" do
      post :create_balance_deal, :account_id => :taro_cache.to_id, :deal => {:balance => 3000,
        :account_id => :taro_cache.to_id,
        :date => {:year => '2010', :month => '7', :day => '7'}
      }
      response.should be_success
      deal = @current_user.balance_deals.find_by_date(Date.new(2010, 7, 7))
      deal.should_not be_nil
      deal.balance.should == 3000
    end
  end


  describe "index" do
    it "セッションに日付情報があるとき正しくリダイレクトされる" do
      get :index, {}, {:user_id => @current_user.id, :target_date => {:year => 2010, :month => 12, :day => 4}}
      response.should redirect_to(monthly_account_deals_path(:year => '2010', :month => '12', :account_id => @current_user.accounts.first.id ))
    end
    it "セッションに日付情報がないとき正しくリダイレクトされる" do
      get :index
      response.should redirect_to(monthly_account_deals_path(:year => Date.today.year.to_s, :month => Date.today.month.to_s, :account_id => @current_user.accounts.first.id ))
    end
  end

  describe "monthly" do
    it "成功する" do
      get :monthly, :year => '2010', :month => '5', :account_id => :taro_cache.to_id
      response.should be_success
    end
  end

  describe "balance" do
    context "pcから" do
      it "アクセスできない" do
        lambda{get :balance, :account_id => :taro_cache.to_id}.should raise_error(UnexpectedUserAgentError)
      end
    end
    context "モバイルから" do
      before do
        set_au_to(request)
      end
      it "アクセスできる" do
        get :balance, :account_id => :taro_cache.to_id
        response.should be_success
      end
    end
  end

end