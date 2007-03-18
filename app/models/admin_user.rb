require "digest/sha1"
class AdminUser < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :name, :password
  validates_uniqueness_of :name
  validates_presence_of :name, :password
  
  def self.login(name, password)
    hashed_password = hash_password(password)
    find(:first, :conditions => ["name = ? and hashed_password = ?", name, hashed_password])
  end
  
  def try_to_login
    AdminUser.login(self.name, self.password)
  end
  
  protected

  def before_create
    self.hashed_password = AdminUser.hash_password(self.password)
  end
  def after_create
    self.password = nil
  end

  private
  def self.hash_password(password)
    raise "no password" unless password
    Digest::SHA1.hexdigest(password)
  end
    
end
