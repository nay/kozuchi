# -*- encoding : utf-8 -*-
class UserObserver < ActiveRecord::Observer
  def after_create(user)
    return if defined?(SKIP_MAIL) && SKIP_MAIL
    UserMailer.signup_notification(user).deliver
  end

  def after_save(user)
    return if defined?(SKIP_MAIL) && SKIP_MAIL
    UserMailer.activation(user).deliver if user.recently_activated?
  end
end
