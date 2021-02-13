require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/friend_spec_helper')

# Acceptanceの作成にモデルを利用しているため、このテストでは両端のUserモデルが必要。
# Acceptanceをfixtureで作成すれば必要ではないがUserなしで衝突しないfixtureを作るのが逆に難しい。
describe Friend::Rejection do
  fixtures :users
  before do
    @user = users(:friend_permission_test_user)
    @target = users(:friend_permission_test_target_user)
  end

  describe "create" do
    it "Acceptanceが存在する場合は事前に削除する" do
      new_acceptance(@user.id, @target.id).save!

      new_rejection(@user.id, @target.id).save!

      expect(Friend::Acceptance.find_by(user_id: @user.id, target_id: @target.id)).to be_nil
      # 相手側のRequestはAcceptanceを削除した時についでに削除される
    end
    it "Rejectionが存在する場合は検証エラー" do
      new_rejection(@user.id, @target.id).save!

      expect(new_rejection(@user.id, @target.id).save).to be_falsey
    end
  end

end

