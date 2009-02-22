require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/welcome/index_mobile" do

  describe "docomo" do
    before(:each) do
      request.user_agent = "DoCoMo/2.0 ISIM0707(c100;TB;W24H16"
      render '/welcome/index_mobile'
    end

    it "簡単ログインボタンが含まれること" do
      response.should include_text("簡単ログイン")
    end
  end

  describe "not docomo" do
    before(:each) do
      request.user_agent = "UP.Browser/3.04-TS11 UP.Link/3.4.4"
      render '/welcome/index_mobile'
    end

    it "簡単ログインボタンが含まれないこと" do
      response.should_not include_text("簡単ログイン")
    end
  end

end
