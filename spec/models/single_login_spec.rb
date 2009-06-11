require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SingleLogin do
  describe "attributes=" do
    it "user_id は一括代入できない" do
      SingleLogin.new(:user_id => 3).user_id.should be_nil
    end
    it "encrypted_passwordは一括代入できない" do
      SingleLogin.new(:crypted_password => "xa12").crypted_password.should be_nil
    end
  end
end
