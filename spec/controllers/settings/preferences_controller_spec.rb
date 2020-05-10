require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::PreferencesController, type: :controller do
  fixtures :users, :preferences

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :show}

  describe "show" do
    it "成功する" do
      get :show
      expect(response).to be_successful
    end
  end

  describe "update" do
    it "成功する" do
      put :update, params: {:preferences => {:business_use => '1', :bookkeeping_style => '1', :color => '#8a4b3f'}}
      expect(response).to redirect_to(settings_preferences_path)
      @preferences = @current_user.preferences
      @preferences.reload
      expect(@preferences).to be_business_use
      expect(@preferences).to be_bookkeeping_style
      expect(@preferences.color).to eq '#8a4b3f'
    end
  end

end
