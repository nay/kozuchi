require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Account with Account::Linking" do
  fixtures :users, :friend_permissions, :friend_requests, :accounts
  set_fixture_class :accounts => 'Account::Base'
  
  describe "set_link" do
    it "太郎の花子から花子の太郎へ双方向にリンクできる" do
      @taro_hanako = accounts(:taro_hanako)
      @taro_hanako.set_link('hanako', '太郎', true)
      @taro_hanako.link.should_not be_nil
      @taro_hanako.link.target_ex_account_id.should == :hanako_taro.to_id
      @taro_hanako.link.target_user_id.should == :hanako.to_id

      @hanako_taro = accounts(:hanako_taro)
      @hanako_taro.link.should_not be_nil
      @hanako_taro.link.target_ex_account_id.should == :taro_hanako.to_id
      @hanako_taro.link.target_user_id.should == :taro.to_id
    end
  end
end
