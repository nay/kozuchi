class UserMailer < ActionMailer::Base
  def signup_notification(user)
    @url = "#{ROOT_URL}/activate/#{user.activation_code}"
    setup_email(user, 'ご登録内容の確認')
  end

  def activation(user)
    @url = "#{ROOT_URL}/"
    setup_email(user, 'ご登録完了のお知らせ')
  end

  def password_notification(user)
    @url = "#{ROOT_URL}/password/#{user.password_token}"
    setup_email(user, 'パスワード変更のご案内')
  end

  protected
    def setup_email(user, subject)
      @user = user
      mail_obj = mail(:to => user.email, :from => SUPPORT_EMAIL_ADDRESS, :subject => "[小槌] #{subject}" )
      mail_obj.transport_encoding = '8bit'
    end
end
