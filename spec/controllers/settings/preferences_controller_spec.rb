require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::PreferencesController do
  fixtures :users, :preferences
  set_fixture_class :preferences => 'Preferences'

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :show}

  describe "show" do
    it "成功する" do
      get :show
      response.should be_success
    end
  end

  describe "update" do
    it "成功する" do
      put :update, :preferences => {:business_use => '1', :bookkeeping_style => '1', :color => '#8a4b3f'}
      response.should redirect_to(settings_preferences_path)
      @preferences = @current_user.preferences(true)
      @preferences.should be_business_use
      @preferences.should be_bookkeeping_style
      @preferences.color.should == '#8a4b3f'
    end
  end

end
