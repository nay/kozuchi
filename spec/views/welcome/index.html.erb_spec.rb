require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/welcome/index" do
  fixtures :users

  describe "ログインしていないとき" do
    before do
      render '/welcome/index'
    end
    it "成功する" do
      response.should be_success
    end
    it "ログインフォームがある" do
      response.should have_tag('input#login')
    end
  end

  describe "ログインしているとき" do
    before do
      login_as :taro
      render '/welcome/index'
    end
    it "成功する" do
      response.should be_success
    end
    it "ログインフォームがない" do
      response.should_not have_tag('input#login')
    end
  end


end
