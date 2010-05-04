require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AccountLinkRequestsController do
  fixtures :users, :accounts, :account_links, :account_link_requests
  set_fixture_class :accounts => 'Account::Base'

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { delete :destroy }

  describe "destroy" do
    before do
      @target_id = Fixtures.identify :hanako_to_taro
      @target_account_id = Fixtures.identify :taro_hanako
    end
    context "目的のAccountLinkRequestがあるとき" do
      it "AccountLinkRequestを削除できる" do
        delete :destroy, :id => @target_id, :account_id => @target_account_id
        response.should redirect_to(settings_account_links_path)
        AccountLinkRequest.find_by_id(@target_id).should be_nil
        flash[:errors].should be_nil
      end
    end
    context "目的のAccountLinkRequestがないとき" do
      before do
        violated '前提エラー' if AccountLinkRequest.find_by_id(99) || Account::Base.find_by_id(99)
      end
      it "ActiveRecord::RecordNotFoundを投げる" do
        lambda{delete :destroy, :id => 99, :account_id => 99}.should raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  
end
