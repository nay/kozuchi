require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountLinkRequest, :no_deals_and_patterns do
  fixtures :users, :accounts, :account_links, :account_link_requests

  describe "create" do
    before do
      # TODO: ほんとはだめな種類だけど
      @account = accounts(:taro_cache)
      @sender = users(:hanako)
      @sender_account = accounts(:hanako_cache)
    end
    it "user_idが自動的に入ること" do
      link_request = @account.link_requests.create(:account_id => @account.id, :sender_id => @sender.id, :sender_ex_account_id => @sender_account.id)
      expect(link_request).not_to be_new_record
      expect(link_request.user_id).to eq @account.user_id
      link_request.reload
      expect(link_request.user_id).to eq @account.user_id
    end
   
  end

  describe "destroy" do
    before do
      @user = users(:taro)
    end
    it "senderのUserが削除されたら対応するレコードが削除されること" do
      raise "前提エラー: 太郎をsenderとするAccountLinkRequestがない" if AccountLinkRequest.where(sender_id: @user.id).empty?
      @user.destroy
      expect(AccountLinkRequest.where(sender_id: @user.id)).to be_empty
    end

  end

end
