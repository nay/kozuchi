class AccountLinkRequest < ApplicationRecord
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :account, :class_name => "Account::Base"

  validates_uniqueness_of :sender_ex_account_id, :scope => [:sender_id, :account_id]

  after_save :set_user_id

  def sender_account
    sender.account(sender_ex_account_id)
  end

  def account_name_with_user
    sender.account_summary(sender_ex_account_id)[:name_with_user]
  end

  private
  # account_id から user_id を自動的に入れる
  def set_user_id
    raise "no account_id" if self.account_id.blank?
    raise "no account for id #{self.account_id}" unless self.account
    self.user_id = account.user_id
    self.class.where(id: self.id).update_all("user_id = #{account.user_id}")
  end

end
