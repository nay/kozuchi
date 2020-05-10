require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe HelpController, type: :controller do
  fixtures :users
  context "ログインしているとき" do
    before do
      login_as :taro
    end
    describe "index" do
      it "成功する" do
        get :index
        expect(response).to be_successful
      end
    end
    describe "functions" do
      it "成功する" do
        get :functions
        expect(response).to be_successful
      end
    end
    describe "faq" do
      it "成功する" do
        get :faq
        expect(response).to be_successful
      end
    end
  end
  context "ログインしていないとき" do
    describe "index" do
      it "成功する" do
        get :index
        expect(response).to be_successful
      end
    end
    describe "functions" do
      it "成功する" do
        get :functions
        expect(response).to be_successful
      end
    end
    describe "faq" do
      it "成功する" do
        get :faq
        expect(response).to be_successful
      end
    end
  end
end