require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ProfitAndLossController do
  fixtures :users, :accounts
  set_fixture_class :accounts => 'Account::Base'
  before do
    login_as :taro
  end
  describe "show" do
    context "口座が十分あるとき" do
      it "monthlyにリダイレクトされる" do
        get :show
        response.should redirect_to(monthly_profit_and_loss_path(:year => Date.today.year, :month => Date.today.month))
      end
    end
    context "口座がないとき" do
      before do
        @current_user.accounts.destroy_all
      end
      it "エラーページが表示される" do
        get :show
        response.should be_success
      end
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, {:year => Date.today.year, :month => Date.today.month}
      response.should be_success
    end
  end
end