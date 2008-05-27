class LoginEngineUser < User

  # Authentication for old users. Define LOGINE_ENGINE_SALT in your envrionment.
  #   find(:first, :conditions => ["login = ? AND salted_password = ? AND verified = 1", login, AuthenticatedUser.salted_password(u.salt, AuthenticatedUser.hashed(pass))])
  def authenticated?(password)
    salted_password == LoginEngineUser.salted_password(salt, LoginEngineUser.hashed(password))
  end

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end
  
  def self.hashed(str)
    raise "LOGIN_ENGINE_SALT must be defined if you need login_engine authentication" unless defined? LOGIN_ENGINE_SALT
    return Digest::SHA1.hexdigest("#{LOGIN_ENGINE_SALT}--#{str}--}")[0..39]
  end
  
  def salted_password
    self.crypted_password
  end
    
end