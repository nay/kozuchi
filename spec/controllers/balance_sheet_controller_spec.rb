require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe BalanceSheetController do
  fixtures :users, :accounts
  set_fixture_class :accounts => 'Account::Base'
  before do
    login_as :taro
  end
  describe "show" do
    it "monthlyにリダイレクトされる" do
      get :show
      response.should redirect_to(monthly_balance_sheet_path(:year => Date.today.year, :month => Date.today.month))
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, {:year => Date.today.year, :month => Date.today.month}
      response.should be_success
    end
  end
end