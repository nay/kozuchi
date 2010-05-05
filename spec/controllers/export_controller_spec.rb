require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ExportController do
  fixtures :users
  before do
    login_as :taro
  end

  describe "GET 'index'" do
    it "成功すること" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'whole'" do
    describe "xml" do
      it "成功すること" do
        get 'whole', :format => "xml"
        response.should be_success
      end
    end
    describe "csv" do
      it "成功すること" do
        get 'whole', :format => "csv"
        response.should be_success
      end
    end
  end
end
