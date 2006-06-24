class UserNotify < ActionMailer::Base
  # extension
  # http://nasuta.seesaa.net/article/17245391.html
  def base64(text)
    if default_charset == 'iso-2022-jp'
      text = NKF.nkf('-j -m0',text)
    end
    text = [text].pack('m').delete("\r\n") 
    "=?#{default_charset}?B?#{text}?="
  end
  def create!(*)
    super
    @mail.body = NKF::nkf('-j',@mail.body)
    @mail
  end

  def signup(user, password, url=nil)
    setup_email(user)

    # Email header info
#    @subject += "#{LoginEngine.config(:app_name)}へようこそ！"
    @subject += " ユーザー登録受付のお知らせ"
    @subject = base64(@subject)

    # Email body substitutions
    @body["name"] = "#{user.lastname} #{user.firstname}"
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
