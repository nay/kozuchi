class Settings::FriendRejectionsController < ApplicationController
  before_action :find_target_user

  # フレンド関係の拒否
  def create
    rejection = current_user.friend_rejections.create(:target_id => @target_user.id)
    flash[:notice] = "#{ERB::Util.h(@target_user.login)}さんとのフレンド関係を拒否しました。" unless rejection.new_record?
    redirect_to settings_friends_path
  end

  # 拒否の撤回
  def destroy
    rejection = current_user.friend_rejections.find_by(target_id: @target_user.id)
    rejection.destroy if rejection
    flash[:notice] = "#{ERB::Util.h(@target_user.login)}さんへのフレンド関係拒否を撤回しました。"
    redirect_to settings_friends_path
  end

  private
  def find_target_user
    @target_user = User.find_by(login: params[:target_login])
    raise ActiveRecord::RecordNotFound if !@target_user || @target_user == current_user
  end
end
