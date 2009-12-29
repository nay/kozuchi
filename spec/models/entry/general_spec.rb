require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../entry_spec_helper')

describe Entry::General do
  fixtures :accounts, :users, :account_links, :friend_permissions, :friend_requests
  set_fixture_class  :accounts => Account::Base
  include EntrySpecHelper

  describe "valid?" do
    it "正しい情報を与えたときにtrueとなる" do
      new_general_entry(:taro_cache, 300).should be_valid
    end

    it "金額に0が与えられるとfalse" do
      new_general_entry(:taro_cache, 0).should_not be_valid
    end

  end

end