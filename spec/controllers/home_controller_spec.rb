require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe HomeController, type: :controller do
  fixtures :users
  describe "index" do

    context "PCログイン" do
      before do
        login_as :taro
      end
      it "成功する" do
        get :index
        expect(response).to be_successful
      end
    end

  end

end
