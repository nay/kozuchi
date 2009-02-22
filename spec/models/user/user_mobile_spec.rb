require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe User::Mobile do
  fixtures :users

  describe "update_mobile_identity!" do
    before do
      @no_mobile_ident_user = users(:no_mobile_ident_user)
      raise "前提：mobile_identityは入っていない" unless @no_mobile_ident_user.mobile_identity.blank?
    end
    it "文字列をいれたらハッシュ化されて格納されること" do
      @no_mobile_ident_user.update_mobile_identity!("abcdefg")
      @no_mobile_ident_user.mobile_identity.should_not be_nil
      @no_mobile_ident_user.mobile_identity.should_not == "abcdefg"
    end
    it "nilを入れたらnilが入ること" do
      @no_mobile_ident_user.update_mobile_identity!(nil)
      @no_mobile_ident_user.mobile_identity.should be_nil
    end
    it "空文字列を入れたらnilが入ること" do
      @no_mobile_ident_user.update_mobile_identity!("")
      @no_mobile_ident_user.mobile_identity.should be_nil
    end
  end
end