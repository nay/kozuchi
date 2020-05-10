class Friend::Rejection < Friend::Permission
  validate :validates_not_rejected

  private
  def validates_not_rejected
    errors.add(:base, "すでにフレンド関係を拒否しています。") if Friend::Rejection.find_by(user_id: self.user_id, target_id: self.target_id)
  end

end