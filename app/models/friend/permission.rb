# -*- encoding : utf-8 -*-
class Friend::Permission < ActiveRecord::Base
  set_table_name "friend_permissions"
  belongs_to :user
  belongs_to :target, :class_name => "User", :foreign_key => "target_id"

  attr_protected :user_id
  
  before_create :destroy_others
  after_save :error_if_repeating

  private
  def destroy_others
    Friend::Permission.find_all_by_user_id_and_target_id(self.user_id, self.target_id).each{|p| p.destroy}
  end
  def error_if_repeating
    raise "user_id must be different from target_id" if self.user_id == self.target_id
  end


end
