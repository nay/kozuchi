require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../mobile_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe MobilesController do
  fixtures :users
  before do
    login_as(:docomo1_user)
  end

  describe "confirm_destroy" do
    it "成功すること" do
      set_docomo_mova_to request
      get :confirm_destroy
      response.should be_success
    end
  end

  describe "destroy" do
    it "mobile_identityが削除できる" do
      set_docomo_mova_to request
      post :destroy, :_method => "delete"
      user = assigns[:current_user].reload
      user.mobile_identity.should be_nil
      response.should redirect_to(home_path)
    end
  end

  describe "update" do
    it "成功する" do
      set_docomo_mova_to request
      put :update
      response.should redirect_to(home_path)
    end
  end

end
