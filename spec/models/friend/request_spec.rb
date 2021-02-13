require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/friend_spec_helper')

describe Friend::Request do
  fixtures :users
  before do
    @user = users(:friend_permission_test_user)
    @target = users(:friend_permission_test_target_user)
    @sender = users(:friend_permission_test_target_user2)
  end
  describe "not_determined" do
    before do
      new_acceptance(@user.id, @target.id).save!
      new_request(@user.id, @sender.id).save!
    end
    it "Permissionのあるtarget_idに対応するRequestは含まれない" do
      expect(@user.friend_requests.not_determined.first.sender_id).to eq @sender.id
    end
  end
  describe "create" do
    it "user_id と sender_id が同じだと例外が発生する" do
      expect{ new_request(@user.id, @user.id).save }.to raise_error(RuntimeError)
    end
  end
end
