require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountLinkRequest do
  fixtures :users, :accounts, :account_links, :account_link_requests
  set_fixture_class  :accounts => Account::Base
  describe "destroy" do
    before do
      @user = users(:taro)
    end
    it "senderのUserが削除されたら対応するレコードが削除されること" do
      raise "前提エラー: 太郎をsenderとするAccountLinkRequestがない" if AccountLinkRequest.find_all_by_sender_id(@user.id).empty?
      @user.destroy
      AccountLinkRequest.find_all_by_sender_id(@user.id).should be_empty
    end

  end

end
