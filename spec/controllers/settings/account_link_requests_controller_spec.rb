require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AccountLinkRequestsController, type: :controller do
  fixtures :users, :accounts, :account_links, :account_link_requests

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login {
    @target_id = Fixtures.identify :hanako_to_taro
    @target_account_id = Fixtures.identify :taro_hanako
    delete :destroy, params: {:id => @target_id, :account_id => @target_account_id}
  }

  describe "destroy" do
    before do
      @target_id = Fixtures.identify :hanako_to_taro
      @target_account_id = Fixtures.identify :taro_hanako
    end
    context "目的のAccountLinkRequestがあるとき" do
      it "AccountLinkRequestを削除できる" do
        delete :destroy, params: {:id => @target_id, :account_id => @target_account_id}
        expect(response).to redirect_to(settings_account_links_path)
        expect(AccountLinkRequest.find_by(id: @target_id)).to be_nil
        expect(flash[:errors]).to be_nil
      end
    end
    context "目的のAccountLinkRequestがないとき" do
      before do
        violated '前提エラー' if AccountLinkRequest.find_by(id: 99) || Account::Base.find_by(id: 99)
      end
      it "ActiveRecord::RecordNotFoundを投げる" do
        expect {delete :destroy, params: {:id => 99, :account_id => 99}}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  
end
