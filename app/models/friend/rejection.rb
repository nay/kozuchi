# -*- encoding : utf-8 -*-
class Friend::Rejection < Friend::Permission
  validate :validates_not_rejected

  private
  def validates_not_rejected
    errors.add(:base, "すでにフレンド関係を拒否しています。") if Friend::Rejection.find_by_user_id_and_target_id(self.user_id, self.target_id)
  end

end