class UserNotify < ActionMailer::Base
  def signup(user, password, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Welcome to #{LoginEngine.config(:app_name)}!"

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["url"] = url || LoginEngine.config(:app_url).to_s
    @body["app_name"] = LoginEngine.config(:app_name).to_s
  end

  def forgot_password(user, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Forgotten password notification"

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["url"] = url || LoginEngine.config(:app_url).to_s
    @body["app_name"] = LoginEngine.config(:app_name).to_s
  end

  def change_password(user, password, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Changed password notification"

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["url"] = url || LoginEngine.config(:app_url).to_s
    @body["app_name"] = LoginEngine.config(:app_name).to_s
  end

  def pending_delete(user, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Delete user notification"

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["url"] = url || LoginEngine.config(:app_url).to_s
    @body["app_name"] = LoginEngine.config(:app_name).to_s
    @body["days"] = LoginEngine.config(:delayed_delete_days).to_s
  end

  def delete(user, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Delete user notification"

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["url"] = url || LoginEngine.config(:app_url).to_s
    @body["app_name"] = LoginEngine.config(:app_name).to_s
  end

  def setup_email(user)
    @recipients = "#{user.email}"
    @from       = LoginEngine.config(:email_from).to_s
    @subject    = "[#{LoginEngine.config(:app_name)}] "
    @sent_on    = Time.now
    @headers['Content-Type'] = "text/plain; charset=#{LoginEngine.config(:mail_charset)}; format=flowed"
  end
end
