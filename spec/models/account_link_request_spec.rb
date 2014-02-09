# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountLinkRequest, :no_deals_and_patterns do
  fixtures :users, :accounts, :account_links, :account_link_requests
  set_fixture_class  :accounts => Account::Base

  describe "create" do
    before do
      # TODO: ほんとはだめな種類だけど
      @account = accounts(:taro_cache)
      @sender = users(:hanako)
      @sender_account = accounts(:hanako_cache)
    end
    it "user_idが自動的に入ること" do
      link_request = @account.link_requests.create(:account_id => @account.id, :sender_id => @sender.id, :sender_ex_account_id => @sender_account.id)
      link_request.new_record?.should be_false
      link_request.user_id.should == @account.user_id
      link_request.reload
      link_request.user_id.should == @account.user_id
    end
   
  end

  describe "destroy" do
    before do
      @user = users(:taro)
    end
    it "senderのUserが削除されたら対応するレコードが削除されること" do
      raise "前提エラー: 太郎をsenderとするAccountLinkRequestがない" if AccountLinkRequest.where(sender_id: @user.id).empty?
      @user.destroy
      AccountLinkRequest.where(sender_id: @user.id).should be_empty
    end

  end

end
