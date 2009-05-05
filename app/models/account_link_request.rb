class AccountLinkRequest < ActiveRecord::Base
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :account, :class_name => "Account::Base"

  validates_uniqueness_of :sender_ex_account_id, :scope => [:sender_id, :account_id]

  def sender_account
    sender.account(sender_ex_account_id)
  end

  def account_name_with_user
    sender.account_summary(sender_ex_account_id)[:name_with_user]
  end

end
