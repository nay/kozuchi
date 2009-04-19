require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Account::Base" do
  fixtures :users, :accounts
  describe "destroy" do
    before do
      @user = users(:taro)
    end
    it "Userを削除したらAccountも削除されること" do
      raise "前提エラー：taroに口座があること" if Account::Base.find_all_by_user_id(@user.id).empty?
      @user.destroy
      Account::Base.find_all_by_user_id(@user.id).should be_empty
    end
  end
end
