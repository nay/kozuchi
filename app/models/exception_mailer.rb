class ExceptionMailer < ActionMailer::Base

  def emergency(e)

    @charset = 'utf-8'
    subject '[KOZUCHI] bug report'
    from 'kozuchi-bugs@everyleaf.com'
    recipients 'kozuchi-bugs@everyleaf.com'

    body :now => Time.now, :exception => e
  end
end
