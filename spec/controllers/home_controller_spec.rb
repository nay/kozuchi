require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../mobile_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe HomeController do
  fixtures :users
  describe "index" do

    context "Docomo mova 機種情報なしでのアクセス" do
      before do
        login_as(:docomo1_user)
      end
      it "@mobile_login_availableがtrueになる" do
        set_docomo_mova_to request
        get :index
        request.mobile?.should be_true
        assigns[:mobile_login_available].should be_true
      end
    end

    context "PCログイン" do
      before do
        login_as :taro
      end
      it "成功する" do
        get :index
        response.should be_success
      end
    end

  end

end
