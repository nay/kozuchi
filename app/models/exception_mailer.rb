class ExceptionMailer < ActionMailer::Base

  def emergency(e)

    @charset = 'utf-8'
    subject '[KOZUCHI] bug report'
    from 'kozuchi-bugs@goas.no-ip.org'
    recipients 'kozuchi-bugs@goas.no-ip.org'

    body :now => Time.now, :exception => e
  end
end
