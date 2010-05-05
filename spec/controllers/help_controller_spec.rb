require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe HelpController do
  fixtures :users
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
  describe "functions" do
    it "成功する" do
      get :functions
      response.should be_success
    end
  end
  describe "faq" do
    it "成功する" do
      get :faq
      response.should be_success
    end
  end
end