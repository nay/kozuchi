require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::FriendRejectionsController do
  fixtures :users, :friend_requests, :friend_permissions

  before do
    login_as :taro
    @current_user.friend_acceptances.find_by_target_id(:hanako.to_id).destroy
  end

  describe "create" do
    it "成功する" do
      post :create, :target_login => 'hanako'
      response.should redirect_to(friends_path)
      @current_user.friend_rejections.find_by_target_id(:hanako.to_id).should_not be_nil
    end
  end

  describe "destroy" do
    it "成功する" do
      @current_user.friend_rejections.create!(:target_id => :hanako.to_id)
      delete :destroy, :target_login => 'hanako'
      response.should redirect_to(friends_path)
      @current_user.friend_rejections.find_by_target_id(:hanako.to_id).should be_nil
    end
  end

end
