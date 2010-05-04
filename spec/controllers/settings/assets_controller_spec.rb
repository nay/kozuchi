require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AssetsController do
  fixtures :users, :preferences, :accounts
  set_fixture_class :accounts => 'Account::Base', :preferences => 'Preferences'


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
      post :create, :account => {:name => '追加', :sort_key => 77}
      response.should redirect_to(settings_assets_path)
      @current_user.assets.find_by_name('追加').should_not be_nil
      flash[:errors].should be_nil
    end
  end

  describe "update_all" do
    before do
      @current_values = {}
      @current_user.assets.each{|a| @current_values[a.id.to_s] = {:name => a.name, :asset_kind => a.asset_kind, :sort_key => a.sort_key}}
    end
    it "成功する" do
      @current_values[Fixtures.identify(:taro_cache).to_s][:name] = "げんきん"
      put :update_all, :account => @current_values
      response.should redirect_to(settings_assets_path)
      @current_user.assets.find_by_name('げんきん').should_not be_nil
      flash[:errors].should be_nil
    end
    it "空の口座名をいれるとエラーメッセージ" do
      @current_values[Fixtures.identify(:taro_cache).to_s][:name] = ""
      put :update_all, :account => @current_values
      response.should be_success
      @current_user.assets.find_by_name('現金').should_not be_nil
      assigns(:accounts).any?{|a| !a.errors.empty?}.should be_true
    end
  end

  describe "destroy" do
    it "成功する" do
      delete :destroy, :id => Fixtures.identify(:taro_cache)
      response.should redirect_to(settings_assets_path)
      Account::Base.find_by_id(Fixtures.identify(:taro_cache)).should be_nil
      flash[:errors].should be_nil
    end
  end

end