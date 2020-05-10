class Friend::Request < ApplicationRecord
  self.table_name = "friend_requests"
  belongs_to :user
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  after_save :error_if_repeating

  scope :not_determined, -> {
    joins("left outer join friend_permissions on friend_requests.user_id = friend_permissions.user_id and friend_requests.sender_id = friend_permissions.target_id"
    ).where("friend_permissions.target_id is null")
  }

  private
  def error_if_repeating
    raise "user_id must be different from sender_id" if self.user_id == self.sender_id
  end

end
