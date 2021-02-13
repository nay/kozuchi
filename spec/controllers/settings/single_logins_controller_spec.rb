require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::SingleLoginsController, type: :controller do
  fixtures :users, :friend_requests, :friend_permissions

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :index }

  describe "index" do
    it "成功する" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "create" do
    it "成功する" do
      post :create, params: {:single_login => {:login => 'hanako', :password => 'hanako'}}
      expect(response).to redirect_to(settings_single_logins_path)
      expect(flash[:errors]).to be_nil
      expect(@current_user.single_logins.find_by(login: 'hanako')).not_to be_nil
    end
    it "パスワードが違うと成功しない" do
      post :create, params: {:single_login => {:login => 'hanako', :password => 'hanako2'}}
      expect(response).to be_successful
      expect(assigns(:single_login).errors).not_to be_empty
      expect(@current_user.single_logins.find_by(login: 'hanako')).to be_nil
    end
  end

end
