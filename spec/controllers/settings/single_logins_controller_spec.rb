require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::SingleLoginsController do
  fixtures :users, :friend_requests, :friend_permissions

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :index }

  describe "index" do
    it "成功する" do
      get :index
      response.should be_success
    end
  end

  describe "create" do
    it "成功する" do
      post :create, :single_login => {:login => 'hanako', :password => 'hanako'}
      response.should redirect_to(settings_single_logins_path)
      flash[:errors].should be_nil
      @current_user.single_logins.find_by_login('hanako').should_not be_nil
    end
    it "パスワードが違うと成功しない" do
      post :create, :single_login => {:login => 'hanako', :password => 'hanako2'}
      response.should be_success
      assigns(:single_login).errors.should_not be_empty
      @current_user.single_logins.find_by_login('hanako').should be_nil
    end
  end

end
