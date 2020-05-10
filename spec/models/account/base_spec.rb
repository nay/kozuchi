require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../entry_spec_helper')

describe "Account::Base", :no_deals_and_patterns do
  fixtures :users, :accounts

  include EntrySpecHelper

  describe "destroy" do
    before do
      @user = users(:taro)
    end
    it "Userを削除したらAccountも削除されること" do
      raise "前提エラー：taroに口座があること" if Account::Base.where(user_id: @user.id).empty?
      @user.destroy
      expect(Account::Base.where(user_id: @user.id)).to be_empty
    end
    it "使われていなければ消せること" do
      account = accounts(:taro_cache)
      expect{ account.destroy }.not_to raise_error
      expect(Account::Base.find_by(id: account.id)).to be_nil
    end
    it "使われていたら消せないこと" do
      entry = new_general_entry(:taro_cache, 300)
      entry.save!
      account = entry.account
      expect{ account.destroy }.to raise_error(Account::Base::UsedAccountException)
      expect(Account::Base.find_by(id: account.id)).not_to be_nil
    end
  end
end
