class Settings::FriendRejectionsController < ApplicationController

  # フレンド関係の拒否
  def create
    target_user = User.find_by_login(params[:target_login])
    if target_user && target_user != current_user
      rejection = current_user.friend_rejections.create(:target_id => target_user.id)
      flash[:notice] = "#{ERB::Util.h(rejection.target.login)}さんとのフレンド関係を拒否しました。" unless rejection.new_record?
    end
    # 基本的に成功するはずなので失敗時は黙ってリダイレクトでOK
    redirect_to friends_path
  end

  # 拒否の撤回
  def destroy
    rejection = current_user.friend_rejections.find(params[:id])
    rejection.destroy
    flash[:notice] = "#{ERB::Util.h(rejection.target.login)}さんへのフレンド関係拒否を撤回しました。"
    redirect_to friends_path
  end
end
