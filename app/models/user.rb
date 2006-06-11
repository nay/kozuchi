require 'digest/sha1'
class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :password, :login_id
  validates_uniqueness_of :login_id
  validates_presence_of :login_id, :password
  has_one   :preferences,
            :class_name => "Preferences",
            :dependent => true
  has_many  :friends,
            :dependent => true
  has_many  :friend_applicants,
            :class_name => 'Friend',
            :foreign_key => 'friend_user_id',
            :dependent => true

  # 双方向に指定level以上のフレンドを返す
  def interactive_friends(level)
    # TODO 効率悪い
    friend_users = []
    for l in friends
      friend_users << l.friend_user if l.friend_level >= level && l.friend_user.friends.detect{|e|e.friend_user_id == self.id && e.friend_level >= level}
    end
    return friend_users
  end

  def self.find_friend_of(user_id, login_id)
    if 2 == Friend.count(:joins => "as fr inner join users as us on ((fr.user_id = us.id and fr.friend_user_id = #{user_id}) or (fr.user_id = #{user_id} and fr.friend_user_id = us.id))",
                   :conditions => ["us.login_id = ? and fr.friend_level > 0", login_id])
      return find_by_login_id(login_id)
    end
  end

  def self.is_friend(user1_id, user2_id)
    return 2 == Friend.count(:conditions => ["(user_id = ? and friend_user_id = ? and friend_level > 0) or (user_id = ? and friend_user_id == ? and friend_level > 0)", user1_id, user2_id, user2_id, user1_id])
  end


  def self.find_by_login_id(login_id)
    find(:first, :conditions => ["login_id = ? ", login_id])
  end

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
    Account.create_default_accounts(self.id)
  end
  
  private
  def self.hash_password(password)
    Digest::SHA1.hexdigest(password)
  end
end
