# old
class AdminController < ApplicationController

  def edit_user
    @user = User.find(params[:id]) if params[:id]
    @title = "管理"
    @user ||= User.new
    @users = User.find(:all)
  end

  def save_user
    @user = User.new(params[:user])
    
    logger.debug(@user)
    p @user
    if @user.save
      flash[:notice] = "ユーザー#{@user.login_id}を追加しました。"
    else
      flash[:notice] = "追加できませんでした。"
    end
    redirect_to(:action => 'edit_user')
  end
end
