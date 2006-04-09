require 'digest/sha1'
class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :password, :login_id
  validates_uniqueness_of :login_id
  validates_presence_of :login_id, :password
  
  def before_create
    self.hashed_password = User.hash_password(self.password)
    p "hashed_password = #{self.hashed_password}"
  end
  def after_create
    @password = nil
  end
  private
  def self.hash_password(password)
    Digest::SHA1.hexdigest(password)
  end
end
