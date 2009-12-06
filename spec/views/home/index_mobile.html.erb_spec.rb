require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../mobile_spec_helper')

describe "/home/index_mobile" do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  describe "docomo FOMA" do
    before(:each) do
      login_as(:docomo1_user) # TODO
      set_docomo_foma_to request
      render '/home/index_mobile'
      raise "前提エラー：identがとれない" if request.mobile.ident.blank?
    end

    it "formにutnがついていないこと" do
      response.should_not include_text(" utn>")
    end
  end

  describe "docomo mova" do
    before(:each) do
      login_as(:docomo2_user)
      set_docomo_mova_to request
      assigns[:mobile_login_available] = true
      render '/home/index_mobile'
    end

    it "formにutnがついていること" do
      response.should include_text(" utn>")
    end
  end

  describe "AU" do
    before(:each) do
      login_as(:au1_user)
      request.user_agent = "UP.Browser/3.04-TS11 UP.Link/3.4.4"
      render '/home/index_mobile'
    end

    it "formにutnがついていないこと" do
      response.should_not include_text(" utn>")
    end
  end

end
