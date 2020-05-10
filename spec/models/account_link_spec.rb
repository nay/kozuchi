require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountLink do
  fixtures :users, :friend_permissions, :friend_requests, :accounts

  before do
    # 前提条件
    raise "前提条件エラー" unless User.where("id in(3, 5)").empty?
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
      expect(@link).not_to be_valid
    end
    it "user_id, target_user_id, target_ex_account_idがあれば検証を通る" do
      expect(@link).to be_valid
    end
    it "user_idがなければ検証エラー" do
      @link.user_id = nil
      expect(@link.save).to be_falsey
    end
    it "target_user_idがなければ検証エラー" do
      @link.target_user_id = nil
      expect(@link.save).to be_falsey
    end
    it "target_ex_account_idがなければ検証エラー" do
      @link.target_ex_account_id = nil
      expect(@link.save).to be_falsey
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
      expect {@link.save}.to raise_error(RuntimeError)
    end
  end
  
  describe "create" do
    it "各属性値が適当でも成功する" do
      @link = AccountLink.new
      @link.user_id = 3
      @link.target_user_id = 5
      @link.target_ex_account_id = 12
      expect(@link.save).to be_truthy
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
        expect(@link.save).to be_truthy
        r = AccountLinkRequest.find_by(sender_id: @user.id)
        expect(r).not_to be_nil
        expect(r.account_id).to eq @target_user_account_for_user.id
        expect(r.sender_ex_account_id).to eq @user_account_for_target_user.id
      end
    end
  end

end
