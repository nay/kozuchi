module User::Mobile

  def update_mobile_identity!(identity)
    self.mobile_identity = identity.blank? ? nil : self.class.encrypt(identity, salt)
    self.save!
  end

end