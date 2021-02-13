class AccountLink < ApplicationRecord
  belongs_to :account, :class_name => "Account::Base", :foreign_key => "account_id"
  belongs_to :target_user, :foreign_key => "target_user_id", :class_name => "User"

  attr_accessor :skip_requesting

  before_validation :set_user_id
  after_create :request_creating_link_request
  before_update {raise "Not Supported"}
  after_destroy :destroy_target_request

#  attr_protected :user_id

  validates_presence_of :target_ex_account_id, :user_id, :target_user_id
  # TODO: target_ex_account_idを最後にもっていくと検証実行で変な不具合ぽい失敗が発生する(Rails2.1)
  validate :validate_ids

  validates_uniqueness_of :account_id, :scope => [:user_id]
  validates_uniqueness_of :target_ex_account_id, :scope => [:target_user_id, :account_id]

  def set_user_id
    self.user_id ||= account.try(:user_id)
  end

  # AcocuntProxyまたはAccountオブジェクトを返す
  def target_account
    raise AssociatedObjectMissingError, "no target_user for #{self.inspect}. target_user_id = #{self.target_user_id}" unless target_user
    target_user.account(self.target_ex_account_id)
  end

  private
  def validate_ids
    errors.add("自分に連携することはできません") if (user_id && user_id == target_user_id) || (account_id && account_id == target_ex_account_id)

  end

  def request_creating_link_request
    target_user.create_link_request(target_ex_account_id, user_id, account_id) if target_user
    true
  end

  def destroy_target_request
    User.find(self.target_user_id).account(self.target_ex_account_id).destroy_link_request(self.user_id, self.account_id)
  end

end
