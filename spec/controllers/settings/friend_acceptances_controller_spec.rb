require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::FriendAcceptancesController, type: :controller do
  fixtures :users, :friend_requests, :friend_permissions

  before do
    login_as :taro
    @current_user.friend_acceptances.find_by(target_id: :hanako.to_id).destroy
  end

  response_should_be_redirected_without_login {post :create, params: {:target_login => 'hanako'}}

  describe "create" do
    it "成功する" do
      post :create, params: {:target_login => 'hanako'}
      expect(response).to redirect_to(settings_friends_path)
      expect(@current_user.friend_acceptances.find_by(target_id: :hanako.to_id)).not_to be_nil
      expect(flash[:alert]).to be_nil
    end
    it "すでにあると失敗する" do
      @current_user.friend_acceptances.create!(:target_id => :hanako.to_id)

      post :create, params: {:target_login => 'hanako'}
      expect(response).to redirect_to(settings_friends_path)
      expect(@current_user.friend_acceptances.find_by(target_id: :hanako.to_id)).not_to be_nil
      expect(flash[:alert]).not_to be_nil
    end
    it "ユーザーIDを指定しないと、指定するよう伝える" do
      post :create, params: {:target_login => ''}
      expect(response).to redirect_to(settings_friends_path)
      expect(flash[:alert]).to eq 'ユーザーIDを入力してください。'
    end
    it "自分を指定すると、指定できないことを伝える" do
      post :create, params: {:target_login => 'taro'}
      expect(response).to redirect_to(settings_friends_path)
      expect(flash[:alert]).to eq '自分を指定することはできません。'
    end
  end

  describe "destroy" do
    it "成功する" do
      @current_user.friend_acceptances.create!(:target_id => :hanako.to_id)
      delete :destroy, params: {:target_login => 'hanako'}
      expect(response).to redirect_to(settings_friends_path)
      expect(@current_user.friend_acceptances.find_by(target_id: :hanako.to_id)).to be_nil
      expect(flash[:alert]).to be_nil
    end
  end

end
