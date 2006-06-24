ActionMailer::Base.class_eval {
  @@inject_one_error = false
  cattr_accessor :inject_one_error

  private
  def perform_delivery_test(mail)
    if inject_one_error
      ActionMailer::Base::inject_one_error = false
      raise "Failed to send email" if raise_delivery_errors
    else
      deliveries << mail
    end
  end
}
