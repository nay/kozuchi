class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'ご登録内容の確認'
    @body[:url]  = "#{ROOT_URL}/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'ご登録完了のお知らせ'
    @body[:url]  = "#{ROOT_URL}/"
  end
  
  def password_notification(user)
    setup_email(user)
    @subject    += "パスワード変更のご案内"
    @body[:url]  = "#{ROOT_URL}/password/#{user.password_token}"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "kozuchi@goas.no-ip.org"
      @subject     = "[小槌] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
