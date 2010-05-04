require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AccountLinksController do
  fixtures :users, :friend_requests, :friend_permissions, :accounts, :account_links, :account_link_requests
  set_fixture_class :accounts => 'Account::Base'

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :index }

  describe "GET 'index'" do
    it "成功する" do
      get :index
      response.should be_success
    end
  end

  describe "destroy" do
    before do
      @target_id = Fixtures.identify(:taro_to_hanako)
      @target_account_id = Fixtures.identify(:taro_hanako)
    end
    it "成功する" do
      delete :destroy, :account_id => @target_account_id, :id => @target_id
      response.should redirect_to(settings_account_links_path)
      AccountLink.find_by_id(@target_id).should be_nil
    end
  end

  describe "create" do
    share_examples_for 'createが成功する' do
      it "成功する" do
        post :create, :linked_account_name => '太郎', :account_id => Fixtures.identify(:taro_hanako), :linked_user_login => 'hanako'
        response.should redirect_to(settings_account_links_path)
        flash[:errors].should be_nil
        AccountLink.find_by_account_id_and_target_user_id(Fixtures.identify(:taro_hanako), Fixtures.identify(:hanako)).should_not be_nil
      end
    end

    context "まだないとき" do
      before do
        account_links(:taro_to_hanako).destroy
      end
      it_should_behave_like 'createが成功する'
    end

    context "すでにあるとき" do
      it_should_behave_like 'createが成功する'
    end
  end

end
