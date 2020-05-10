require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe BalanceSheetController, type: :controller do
  fixtures :users, :accounts
  before do
    login_as :taro
  end
  describe "show" do
    it "monthlyにリダイレクトされる" do
      get :show
      expect(response).to redirect_to(monthly_balance_sheet_path(:year => Time.zone.today.year, :month => Time.zone.today.month))
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, params: {:year => Time.zone.today.year, :month => Time.zone.today.month}
      expect(response).to be_successful
    end
  end
end