# フレンド設定
class Settings::FriendsController < ApplicationController
  layout 'main'

  def index
    # フレンド関係をもっている、あるいは向こうからこちらにフレンド関係をもっている user のリストを得る
    @friends = Friend.get_all(@user.id)
    for f in @friends
      p f.my_level
    end
    
  end
  
  def create_friend
    friend_login_id = @params[:friend_login_id]
    if !friend_login_id || friend_login_id == ""
      flash_error("ユーザーIDを入力してください。")
      redirect_to(:action => 'index')
      return
    end

    friend_user = get_friend_user(friend_login_id)
    return if !friend_user
    
    save_friend(Friend.new(:user_id => @user.id, :friend_user_id => friend_user.id, :friend_level => 1), "ユーザー'#{friend_login_id}'にフレンド申請をしました。")
  end
  
  def accept_friend
    friend_user = User.find_by_login_id(params[:friend])
    return if !friend_user
    
    save_friend(Friend.new(:user_id => @user.id, :friend_user_id => friend_user.id, :friend_level => 1), "#{friend_user.login_id}さんからのフレンド申請を承諾しました。")
  end
  
  def clear_friend
    friend_user = User.find_by_login_id(params[:friend])
    return if !friend_user
    
    friend = Friend.find(:first, :conditions => ["user_id = ? and friend_user_id = ?", @user.id, friend_user.id])
    before_level = friend.friend_level
    friend.destroy if friend
    if before_level == -1
      flash_notice("#{friend_user.login_id}さんへのフレンド拒否状態を解除しました。フレンド登録するには新たに申請を行ってください。")
    else
      flash_notice("#{friend_user.login_id}さんへのフレンド申請を取り消しました。フレンド登録するには新たに申請を行ってください。")
    end
    
    redirect_to(:action => 'index')
  end
  
  def reject_friend
    friend_user = User.find_by_login_id(params[:friend])
    return if !friend_user
    friend = Friend.find(:first, :conditions => ["user_id = ? and friend_user_id = ?", @user.id, friend_user.id])
    friend ||= Friend.new(:user_id => @user.id, :friend_user_id => friend_user.id)
    
    friend.friend_level = -1
    
    save_friend(friend, "#{friend_user.login_id}さんとフレンドになることを拒否しました。")
  end
  
  def get_friend_user(friend_login_id)
    friend_user = User.find_by_login_id(friend_login_id)
    if !friend_user
      flash_error("ユーザー'#{friend_login_id}'を見つけられませんでした。IDが合っているか確認してください。")
      redirect_to(:action => 'index')
      return nil
    end
    return friend_user
  end
  
  def save_friend(friend, notice)
    begin
      friend.save!
      flash_notice(notice)
    rescue
      flash_validation_errors(friend)
    end
    
    redirect_to(:action => 'index')
  end

end
