class SingleLogin < ApplicationRecord
  belongs_to :user
  attr_accessor :password
#  attr_protected :user_id, :crypted_password

  validates_presence_of :login, :password
  validate :validate_account

  def active?
    return false if crypted_password.blank? || login.blank?
    target_user = User.find_by(login: login)
    return false unless target_user
    target_user.crypted_password == crypted_password
  end

  private
  def validate_account
    return if login.blank? || password.blank?
    target_user = User.find_by(login: login)
    if target_user
      if target_user == self.user
        errors.add(:base, "自分のアカウントへのシングルログイン設定は登録できません。")
        return
      end
      if target_user.authenticated?(password)
        self.crypted_password = target_user.crypted_password
        return # OK
      end
    end
    errors.add(:base, "#{ERB::Util.h(login)}さんのアカウントにログインできません。")
  end

end
