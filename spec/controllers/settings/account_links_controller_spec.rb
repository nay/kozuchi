require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Settings::AccountLinksController do
  fixtures :users

  before do
    login_as :taro
  end

  describe "GET 'index'" do
    it "成功すること" do
      get :index
      response.should be_success
    end
  end

end
