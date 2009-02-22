require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe User::Mobile do
  fixtures :users

  describe "authenticate_with_mobile_identity" do
    before do
      @mobile_user = users(:no_mobile_ident_user)
      @mobile_user.update_mobile_identity!("abcdefg", "userAgentX")
    end

    it "正しいidentとsaltで認証される" do
      User.authenticate_with_mobile_identity("abcdefg", "userAgentX").should == @mobile_user
    end
    it "saltが違うと認証されない" do
      User.authenticate_with_mobile_identity("abcdefg", "userAgentY").should be_nil
    end
    it "identが違うと認証されない" do
      User.authenticate_with_mobile_identity("bcdefgh", "userAgentX").should be_nil
    end
    it "identがnilだとnilが返る" do
      User.authenticate_with_mobile_identity(nil, "userAgentX").should be_nil
    end
    it "saltがnilだとnilが返る" do
      User.authenticate_with_mobile_identity("abcdefg", nil).should be_nil
    end
  end

  describe "update_mobile_identity!" do
    before do
      @no_mobile_ident_user = users(:no_mobile_ident_user)
      raise "前提：mobile_identityは入っていない" unless @no_mobile_ident_user.mobile_identity.blank?
    end
    it "文字列をいれたらハッシュ化されて格納されること" do
      @no_mobile_ident_user.update_mobile_identity!("abcdefg", "userAgentX")
      @no_mobile_ident_user.mobile_identity.should_not be_nil
      @no_mobile_ident_user.mobile_identity.should_not == "abcdefg"
    end
    it "identにnilを入れたらnilが入ること" do
      @no_mobile_ident_user.update_mobile_identity!(nil, "userAgentX")
      @no_mobile_ident_user.mobile_identity.should be_nil
    end
    it "空文字列を入れたらnilが入ること" do
      @no_mobile_ident_user.update_mobile_identity!("", "userAgentX")
      @no_mobile_ident_user.mobile_identity.should be_nil
    end
    it "saltにnilを入れると例外が出る" do
      lambda {@no_mobile_ident_user.update_mobile_identity!("abcdefg", nil)}.should raise_error(RuntimeError)
    end
  end

  describe "clear_mobile_identity!" do
    before do
      @user = users(:docomo1_user)
      raise "前提エラー：mobile_identityがない" if @user.mobile_identity.blank?
    end
    it "identityがnilになること" do
      @user.clear_mobile_identity!
      @user.mobile_identity.should be_nil
    end
  end
end