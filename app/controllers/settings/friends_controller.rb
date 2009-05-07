# フレンド設定
class Settings::FriendsController < ApplicationController
  layout 'main'
  menu_group "高度な設定"
  menu "フレンド"

  def index
    @requests = current_user.friend_requests.not_determined
    @acceptances = current_user.friend_acceptances
    @rejections = current_user.friend_rejections
  end

  def create
    target_login = params[:target_login]
    if target_login.blank?
      flash_error("ユーザーIDを入力してください。")
      redirect_to friends_path
      return
    end
    target_user = User.find_by_login(target_login)
    if !target_user
      flash_error("指定されたユーザーが見つかりません。")
      redirect_to friends_path
      return
    elsif target_user == current_user
      flash_error("自分を指定することはできません。")
      redirect_to friends_path
      return
    end
    @acceptance = current_user.friend_acceptances.build(:target_id => target_user.id)
    if @acceptance.save
      flash[:notice] = "#{ERB::Util.h @acceptance.target.login}さんをフレンドに登録しました。"
    else
      flash_validation_errors(@acceptance)
      flash[:target_login] = target_login
    end
    redirect_to friends_path
  end

  def destroy
    acceptance = current_user.friend_acceptances.find(params[:id])
    acceptance.destroy
    flash[:notice] = "#{ERB::Util.h acceptance.target.login}さんをフレンドから削除しました。"
    redirect_to friends_path
  end


end
