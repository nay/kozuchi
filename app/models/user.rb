class User < ActiveRecord::Base
  include LoginEngine::AuthenticatedUser

  has_one   :preferences,
            :class_name => "Preferences",
            :dependent => :destroy
  has_many  :friends,
            :dependent => :destroy
  has_many  :friend_applicants,
            :class_name => 'Friend',
            :foreign_key => 'friend_user_id',
            :dependent => :destroy
  has_many  :accounts,
            :class_name => 'Account::Base',
            :dependent => :destroy,
            :include => [:associated_accounts, :any_entry], # 削除に関係がある
            :order => 'accounts.sort_key' do
              # 指定した account_type のものだけを抽出する
              def types_in(*account_types)
                account_types = account_types.flatten
                self.select{|a| account_types.detect{|t| a.type_in?(t)} }
              end
              
              # ハッシュに指定された内容に更新する。typeも変更する。
              # udpate も update_all もすでにあるので一応別名でつけた。
              def update_all_with(all_attributes)
                return unless all_attributes
                Account::Base.transaction do
                  for account in self
                    account_attributes = all_attributes[account.id.to_s]
                    next unless account_attributes
                    account_attributes = account_attributes.clone
                    # user_id は指定させない
                    account_attributes.delete(:user_id)
                    # 資産種類を変える場合はクラスを変える必要があるのでとっておく
                    new_asset_name = account_attributes.delete(:asset_name)
                    old_account_name = account.name
                    account.attributes = account_attributes
                    account.save!
                    # type の変更
                    if new_asset_name && new_asset_name != account.asset_name
                      target_type = Account::Asset.asset_name_to_class(new_asset_name)
                      # 変更可能なものでなければ例外を発生する
                      raise Account::IllegalClassChangeException.new(old_account_name, new_asset_name) unless account.changable_asset_types.include? target_type
                      # object ベースではできないので sql ベースで
                      Account::Base.update_all("type = '#{Account::Asset.asset_name_to_class(new_asset_name)}'", "id = #{account.id}") 
                    end
                  end
                end
              end
            end

  def default_asset
    accounts.types_in(:asset).first
  end

  # all logic has been moved into login_engine/lib/login_engine/authenticated_user.rb
  def login_id
    self.login
  end
  
  # 双方向に指定level以上のフレンドを返す
  def interactive_friends(level)
    # TODO 効率悪い
    friend_users = []
    for l in friends(true)
      friend_users << l.friend_user if l.friend_level >= level && l.friend_user.friends(true).detect{|e|e.friend_user_id == self.id && e.friend_level >= level}
    end
    return friend_users
  end

  def self.find_friend_of(user_id, login_id)
    if 2 == Friend.count(:joins => "as fr inner join users as us on ((fr.user_id = us.id and fr.friend_user_id = #{user_id}) or (fr.user_id = #{user_id} and fr.friend_user_id = us.id))",
                   :conditions => ["us.login = ? and fr.friend_level > 0", login_id])
      return find_by_login_id(login_id)
    end
  end

  def self.is_friend(user1_id, user2_id)
    return 2 == Friend.count(:conditions => ["(user_id = ? and friend_user_id = ? and friend_level > 0) or (user_id = ? and friend_user_id == ? and friend_level > 0)", user1_id, user2_id, user2_id, user1_id])
  end


  def self.find_by_login_id(login_id)
    find(:first, :conditions => ["login = ? ", login_id])
  end
  
  # 指定された期間の取引データを取得する。
  # TODO: 口座によらない自由な期間のメソッドがほしくなったら Account に別のスタティックを作りここのデフォルトをnilにしてよびかえる
  def deals(start_date, end_date, accounts)
    BaseDeal.get_for_accounts(self.id, start_date, end_date, accounts)
  end
  
  def deal_exists?(date)
    BaseDeal.exists?(self.id, date)
  end
  
  # このユーザーが使える asset_type (Class) リストを返す
  def available_asset_types
    Account::Asset.types.find_all{|type| !type.business_only? || preferences.business_use? }
  end
  
  protected
  
  def after_create
    create_preferences()
    Account::Base.create_default_accounts(self.id)
  end
  
end
