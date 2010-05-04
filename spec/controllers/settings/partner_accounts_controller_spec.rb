require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::PartnerAccountsController do
  fixtures :users, :accounts
  set_fixture_class :accounts => 'Account::Base'

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login {get :index}

  describe "index" do
    it "成功する" do
      get :index
      response.should be_success
    end
  end

  describe "update" do
    before do
      @account = accounts(:taro_hanako)
    end
    it "まだない場合に設定できる" do
      violate '前提エラー' if @account.partner_account_id

      put :update, :account_id => @account.id, :account => {:partner_account_id => :taro_bank.to_id}

      response.should redirect_to(settings_partner_accounts_path)
      @account.reload
      @account.partner_account_id.should == :taro_bank.to_id
    end
    it "ほかのユーザーの勘定に対して設定できない" do

      lambda{ put :update, :account_id => :hanako_taro.to_id }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

end
