require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountLink do
  describe "attributes=" do
    it "target_user_idは一括で指定できない" do
      link = AccountLink.new(:target_user_id => 15)
      link.target_user_id.should be_nil
    end
    it "target_ex_account_idは一括で指定できない" do
      link = AccountLink.new(:target_ex_account_id => 99)
      link.target_ex_account_id.should be_nil
    end
    it "user_idは一括指定できない" do
      link = AccountLink.new(:user_id => 3)
      link.user_id.should be_nil
    end
  end
  describe "validate" do
    before do
      @link = AccountLink.new
      @link.user_id = 3
      @link.target_user_id = 5
      @link.target_ex_account_id = 12
    end
    it "user_id, target_user_id, target_ex_account_idがあれば検証を通る" do
      @link.valid?.should be_true
    end
    it "user_idがなければ検証エラー" do
      @link.user_id = nil
      @link.save.should be_false
    end
    it "target_user_idがなければ検証エラー" do
      @link.target_user_id = nil
      @link.save.should be_false
    end
    it "target_ex_account_idがなければ検証エラー" do
      @link.target_ex_account_id = nil
      @link.save.should be_false
    end
  end

  describe "update" do
    before do
      @link = AccountLink.new
      @link.user_id = 3
      @link.target_user_id = 5
      @link.target_ex_account_id = 12
      @link.save
    end
    it "例外が発生する" do
      lambda{@link.save}.should raise_error(RuntimeError)
    end
  end

end
