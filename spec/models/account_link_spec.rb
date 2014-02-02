# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountLink do
  fixtures :users, :friend_permissions, :friend_requests, :accounts
  set_fixture_class  :accounts => Account::Base  

  before do
    # 前提条件
    raise "前提条件エラー" unless User.where("id in(3, 5)").empty?
  end
  describe "attributes=" do
    it "user_idは一括指定できない" do
      expect{AccountLink.new(:user_id => 3)}.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end
  end
  describe "validate" do
    before do
      # 適当な数値
      @link = AccountLink.new
      @link.user_id = 3
      @link.target_user_id = 5
      @link.target_ex_account_id = 12
    end
    it "同じ口座で２つ以上作れない" do
      already = AccountLink.new
      already.user_id = 3
      already.account_id = 7
      already.target_user_id = 7
      already.target_ex_account_id = 24
      already.save!
      @link.account_id = 7
      @link.should_not be_valid
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
  
  describe "create" do
    it "各属性値が適当でも成功する" do
      @link = AccountLink.new
      @link.user_id = 3
      @link.target_user_id = 5
      @link.target_ex_account_id = 12
      @link.save.should be_true
    end
    describe "対応するフレンドな相手ユーザーオブジェクトが取得できる時" do
      before do
        @user = users(:account_link_test_user)
        @user_account_for_target_user = accounts(:account_link_test_user_1)
        @target_user = users(:account_link_test_target_user)
        @target_user_account_for_user = accounts(:account_link_test_target_user_1)
        raise "前提条件エラー：フレンドでない" unless @user.friend?(@target_user)
        @link = AccountLink.new
        @link.user_id = @user.id
        @link.account_id = @user_account_for_target_user.id
        @link.target_user_id = @target_user.id
        @link.target_ex_account_id = @target_user_account_for_user.id
      end
      it "成功して、相手側にaccount_link_requestが作られる" do
        @link.save.should be_true
        r = AccountLinkRequest.find_by_sender_id(@user.id)
        r.should_not be_nil
        r.account_id.should == @target_user_account_for_user.id
        r.sender_ex_account_id.should == @user_account_for_target_user.id
      end
    end
  end

end
