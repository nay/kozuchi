require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/friend_spec_helper')

# アプリケーション間の通信を視野にいれた作りのため、このテストには両端のUserモデルが必要。
describe Friend::Acceptance do
  fixtures :users
  before do
    @user = users(:friend_permission_test_user)
    @target = users(:friend_permission_test_target_user)
  end

  describe "attributes=" do
    it "user_idは一括で指定できない" do
      a = Friend::Acceptance.new(:user_id => @user.id)
      a.user_id.should be_nil
    end
  end

  describe "create" do
    it "user_idとtarget_idが同じものを登録しようとすると例外が発生する" do
      lambda{new_rejection(@user.id, @user.id).save}.should raise_error(RuntimeError)
    end

    it "Rejectionが存在する場合は検証エラーとなる" do
      new_rejection(@user.id, @target.id).save!

      new_acceptance(@user.id, @target.id).save.should be_false
    end
    it "Acceptanceが存在する場合は検証エラーとなる" do
      new_acceptance(@user.id, @target.id).save!

      new_acceptance(@user.id, @target.id).save.should be_false
    end
    it "相手側のRequestレコードが作成される" do
      new_acceptance(@user.id, @target.id).save!

      find_request(@target.id, @user.id).should_not be_nil
    end
  end

  describe "destroy" do
    before do
      @acceptance = new_acceptance(@user.id, @target.id)
      @acceptance.save! # 相手側のリクエストが作られる
    end
    it "相手側のRequestがあれば削除される" do
      @acceptance.destroy # 削除

      find_request(@target.id, @user.id).should be_nil
    end

  end

end


