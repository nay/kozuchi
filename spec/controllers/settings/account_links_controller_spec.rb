require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AccountLinksController, type: :controller do
  fixtures :users, :friend_requests, :friend_permissions, :accounts, :account_links, :account_link_requests

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :index }

  describe "GET 'index'" do
    it "成功する" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "destroy" do
    before do
      @target_id = Fixtures.identify(:taro_to_hanako)
      @target_account_id = Fixtures.identify(:taro_hanako)
    end
    it "成功する" do
      delete :destroy, params: {:account_id => @target_account_id, :id => @target_id}
      expect(response).to redirect_to(settings_account_links_path)
      expect(AccountLink.find_by(id: @target_id)).to be_nil
    end
  end

  describe "create" do
    shared_examples_for 'createが成功する' do
      it "成功する" do
        post :create, params: {:linked_account_name => '太郎', :account_id => Fixtures.identify(:taro_hanako), :linked_user_login => 'hanako'}
        expect(response).to redirect_to(settings_account_links_path)
        expect(flash[:errors]).to be_nil
        expect(AccountLink.find_by(account_id: Fixtures.identify(:taro_hanako), target_user_id: Fixtures.identify(:hanako))).not_to be_nil
      end
    end

    context "まだないとき" do
      before do
        account_links(:taro_to_hanako).destroy
      end
      it_behaves_like 'createが成功する'
    end

    context "すでにあるとき" do
      it_behaves_like 'createが成功する'
    end
  end

end
