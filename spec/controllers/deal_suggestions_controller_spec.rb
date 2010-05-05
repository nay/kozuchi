require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe DealSuggestionsController do
  fixtures :users
  
  before do
    login_as :taro
  end
  describe "index" do
    it "成功する" do
      get :index, :keyword => 'テスト'
      response.should be_success
    end
  end
  
end