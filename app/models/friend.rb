class Friend < ActiveRecord::Base
  belongs_to :friend_user,
             :class_name => 'User',
             :foreign_key => 'friend_user_id'
  belongs_to :user
  attr_accessor :my_level
  validates_presence_of :friend_level, :message => "フレンドレベルは省略できません。"
  validates_uniqueness_of :friend_user_id, :scope => "user_id", :message => "すでにフレンド関係が登録されています。"

  def self.get_all(user_id)
    friends = find(:all, :conditions => ['user_id = ?', user_id])
    applicants = find(:all, :conditions => ['friend_user_id = ? and friend_level != -1', user_id])
    for f in friends
      f.my_level = 0
    end
    for applicant in applicants
      # すでにfriends にあれば、my_levelを足す
      f = friends.find {|e| e.friend_user_id == applicant.user_id}
      if f
        f.my_level = applicant.friend_level
      # なければ新しいオブジェクトを作る
      else
        f =  Friend.new(:user_id => user_id, :friend_user_id => applicant.user_id, :friend_level => 0, :my_level => applicant.friend_level)
        friends << f
      end
    end
    return friends
  end
  
  def validate
    # 相手から拒否登録されていたらセーブできない
    f = Friend.find(:first, :conditions => ["user_id = ? and friend_user_id = ?", self.friend_user_id, self.user_id])
    if f && f.friend_level == -1
      errors.add(:friend_level, "#{f.user.login_id}さんはフレンド拒否中です。")
    end
    # 関係0はセーブできない
    if self.friend_level == 0
      errors.add(:friend_level, "システムエラー：friend_level に0は設定できません。")
    end
  end
  
  def after_save
    if self.friend_level == -1
      Friend.delete_all(["user_id = ? and friend_user_id = ?", self.friend_user_id, self.user_id])
    end
  end
  
  def is_applied
    return self.friend_level == 0 && @my_level > 0
  end
  
  def is_rejecting
    return self.friend_level == -1
  end
  
  def is_applying
    return self.friend_level > 0 && @my_level == 0
  end
  
  def is_friend
    return self.friend_level > 0 && @my_level > 0
  end
  
  # このフレンドの名前と同じ債権口座がある
  def exists_account
    if is_friend
      return Account::Credit.find(:first, :conditions => ["user_id = ? and name =?", self.user_id, self.friend_user.login_id])
    end
    false
  end
  
  def friend_status
    if @my_level < 0
      return "フレンド関係を断られています。"
    end
    if self.friend_level == 1
      if @my_level > 0
        return "フレンド"
      else
        return "フレンド申請中"
      end
    end
    if self.friend_level == 0
      if @my_level > 0
        return "フレンド申請されています。"
      end
    end
    return ""
  end
  
end
