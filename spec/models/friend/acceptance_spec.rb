require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/friend_spec_helper')

# アプリケーション間の通信を視野にいれた作りのため、このテストには両端のUserモデルが必要。
describe Friend::Acceptance do
  fixtures :users
  before do
    @user = users(:friend_permission_test_user)
    @target = users(:friend_permission_test_target_user)
    @target2 = users(:friend_permission_test_target_user2)
  end

  describe "create" do
    it "user_idとtarget_idが同じものを登録しようとすると例外が発生する" do
      expect{ new_rejection(@user.id, @user.id).save }.to raise_error(RuntimeError)
    end

    it "Rejectionが存在する場合は検証エラーとなる" do
      new_rejection(@user.id, @target.id).save!

      expect(new_acceptance(@user.id, @target.id).save).to be_falsey
    end
    it "Acceptanceが存在する場合は検証エラーとなる" do
      new_acceptance(@user.id, @target.id).save!

      expect(new_acceptance(@user.id, @target.id).save).to be_falsey
    end
    it "相手側のRequestレコードが作成される" do
      new_acceptance(@user.id, @target.id).save!

      expect(find_request(@target.id, @user.id)).not_to be_nil
    end
    it "別のacceptanceがすでにあっても干渉しない" do
      new_acceptance(@user.id, @target2.id).save!
      new_acceptance(@user.id, @target.id).save!
      expect(find_acceptance(@user.id, @target2.id)).not_to be_nil
    end
  end

  describe "destroy" do
    before do
      @acceptance = new_acceptance(@user.id, @target.id)
      @acceptance.save! # 相手側のリクエストが作られる
    end
    it "相手側のRequestがあれば削除される" do
      @acceptance.destroy # 削除

      expect(find_request(@target.id, @user.id)).to be_nil
    end

  end

end


