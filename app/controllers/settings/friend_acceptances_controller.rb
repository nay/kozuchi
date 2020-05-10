class Settings::FriendAcceptancesController < ApplicationController
  before_action :find_target_user

  def create
    if !@target_user
      if params[:target_login].blank?
        flash_error("ユーザーIDを入力してください。")
        redirect_to settings_friends_path
        return
      end
      flash_error("指定されたユーザーが見つかりません。")
      redirect_to settings_friends_path
      return
    elsif @target_user == current_user
      flash_error("自分を指定することはできません。")
      redirect_to settings_friends_path
      return
    end
    @acceptance = current_user.friend_acceptances.build(:target_id => @target_user.id)
    if @acceptance.save
      flash[:notice] = "#{ERB::Util.h @target_user.login}さんをフレンドに登録しました。"
    else
      flash_validation_errors(@acceptance)
      flash[:target_login] = params[:target_login]
    end
    redirect_to settings_friends_path
  end

  def destroy
    raise ActiveRecord::RecordNotFound if !@target_user || @target_user == current_user
    acceptance = current_user.friend_acceptances.find_by(target_id: @target_user.id)
    acceptance.destroy if acceptance
    flash[:notice] = "#{ERB::Util.h @target_user.login}さんをフレンドから削除しました。"
    redirect_to settings_friends_path
  end

  private
  def find_target_user
    @target_user = User.find_by(login: params[:target_login])
  end
end