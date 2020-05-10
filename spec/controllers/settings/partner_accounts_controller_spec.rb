require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::PartnerAccountsController, type: :controller do
  fixtures :users, :accounts

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login {get :index}

  describe "index" do
    it "成功する" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "update" do
    before do
      @account = accounts(:taro_hanako)
    end
    it "まだない場合に設定できる" do
      violate '前提エラー' if @account.partner_account_id

      put :update, params: {:account_id => @account.id, :account => {:partner_account_id => :taro_bank.to_id}}

      expect(response).to redirect_to(settings_partner_accounts_path)
      @account.reload
      expect(@account.partner_account_id).to eq :taro_bank.to_id
    end
    it "ほかのユーザーの勘定に対して設定できない" do

      expect { put :update, params: {:account_id => :hanako_taro.to_id} }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

end
