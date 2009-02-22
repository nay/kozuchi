require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/home/index_mobile" do

  describe "docomo" do
    before(:each) do
      request.user_agent = "DoCoMo/2.0 ISIM0707(c100;TB;W24H16"
      render '/home/index_mobile'
    end

    it "formにutnがついていること" do
      response.should include_text(" utn>")
    end
  end

  describe "not docomo" do
    before(:each) do
      request.user_agent = "UP.Browser/3.04-TS11 UP.Link/3.4.4"
      render '/home/index_mobile'
    end

    it "formにutnがついていないこと" do
      response.should_not include_text(" utn>")
    end
  end

end
