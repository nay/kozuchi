require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../entry_spec_helper')

describe "Account::Base" do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  include EntrySpecHelper

  describe "destroy" do
    before do
      @user = users(:taro)
    end
    it "Userを削除したらAccountも削除されること" do
      raise "前提エラー：taroに口座があること" if Account::Base.find_all_by_user_id(@user.id).empty?
      @user.destroy
      Account::Base.find_all_by_user_id(@user.id).should be_empty
    end
    it "使われていなければ消せること" do
      account = accounts(:taro_cache)
      lambda{account.destroy}.should_not raise_error
      Account::Base.find_by_id(account.id).should be_nil
    end
    it "使われていたら消せないこと" do
      entry = new_general_entry(:taro_cache, 300)
      entry.save!
      account = entry.account
      lambda{account.destroy}.should raise_error(Account::Base::UsedAccountException)
      Account::Base.find_by_id(account.id).should_not be_nil
    end
  end
end
