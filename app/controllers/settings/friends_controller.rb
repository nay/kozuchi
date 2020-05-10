# フレンド設定
class Settings::FriendsController < ApplicationController
  menu_group "連携"
  menu "フレンド"

  def index
    @requests = current_user.friend_requests.not_determined
    @acceptances = current_user.friend_acceptances
    @rejections = current_user.friend_rejections
  end

end
