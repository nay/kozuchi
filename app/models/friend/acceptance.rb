class Friend::Acceptance < Friend::Permission
  validate :validates_not_rejected, :validates_not_accepted
  after_create :create_target_request
  after_destroy :destroy_target_request

  scope :requested, -> { joins("inner join friend_requests on friend_permissions.user_id = friend_requests.user_id and friend_permissions.target_id = friend_requests.sender_id") }

  def accepted_by_target?
    target.friend_acceptances.find_by(target_id: self.user_id) != nil
  end
  
  private
  def create_target_request
    target.send_friend_request_from!(user)
  end
  def destroy_target_request
    target.cancel_friend_request_from!(user)
  end

  def validates_not_rejected
    errors.add(:base, "フレンド関係を拒否している相手のため、フレンド登録できません。登録するには拒否を撤回してください。") if Friend::Rejection.find_by(user_id: self.user_id, target_id: self.target_id)
  end
  def validates_not_accepted
    errors.add(:base, "すでにフレンド登録されています。") if Friend::Acceptance.find_by(user_id: self.user_id, target_id: self.target_id)
  end
end