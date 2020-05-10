require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::FriendsController, type: :controller do
  fixtures :users, :friend_requests, :friend_permissions

  before do
    login_as :taro
  end

  describe "index" do
    it "成功する" do
      get :index
      expect(response).to be_successful
    end
  end

end
