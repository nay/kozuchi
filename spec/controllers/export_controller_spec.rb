require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExportController do
  fixtures :users

  describe "GET 'index'" do
    before do
      login_as :taro
    end
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end
end
