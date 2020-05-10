require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ExportController, type: :controller do
  fixtures :users
  before do
    login_as :taro
  end

  describe "GET 'index'" do
    it "成功すること" do
      get 'index'
      expect(response).to be_successful
    end
  end

  describe "GET 'whole'" do
    describe "xml" do
      it "成功すること" do
        get 'whole', params: {:format => "xml", :filename => "export"}
        expect(response).to be_successful
      end
    end
    describe "csv" do
      it "成功すること" do
        get 'whole', params: {:format => "csv", :filename => "export"}
        expect(response).to be_successful
      end
    end
  end
end
