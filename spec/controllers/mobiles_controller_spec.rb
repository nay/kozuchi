require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MobilesController do
  fixtures :users

  describe "GET confirm_destroy" do
    before do
      login_as(:docomo1_user)
    end
    it "成功すること" do
      set_docomo_mova_to request
      get :confirm_destroy
      response.should be_success
    end
  end

  describe "DELETE destroy" do
    before do
      login_as(:docomo1_user)
    end
    it "mobile_identityが削除できる" do
      set_docomo_mova_to request
      post :destroy, :_method => "delete"
      user = assigns[:current_user].reload
      user.mobile_identity.should be_nil
      response.should redirect_to(home_path)
    end
  end

end
