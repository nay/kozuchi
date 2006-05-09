require 'digest/sha1'
class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :password, :login_id
  validates_uniqueness_of :login_id
  validates_presence_of :login_id, :password
  has_one :preferences,
          :class_name => "Preferences",
          :dependent => true

  def self.login(login_id, password)
    hashed_password = hash_password(password || "")
    find(:first,
         :conditions => ["login_id = ? and hashed_password = ?", 
                          login_id, hashed_password] )
  end
  def try_to_login
    User.login(self.login_id, self.password)
  end

  def before_save
    self.hashed_password = User.hash_password(self.password)
  end
  def after_create
    @password = nil
  end
  
  private
  def self.hash_password(password)
    Digest::SHA1.hexdigest(password)
  end
end
