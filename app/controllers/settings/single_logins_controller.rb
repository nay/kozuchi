class Settings::SingleLoginsController < ApplicationController
  layout 'main'
  menu_group "設定"
  menu "シングルログイン"

  before_filter :find_single_login, :only => [:destroy]

  def index
    @single_login = current_user.single_logins.build
    current_user.single_logins(true)
  end

  def create
    @single_login = current_user.single_logins.build(params[:single_login])
    if @single_login.save
      flash[:notice] = "#{ERB::Util.h(@single_login.login)}さんへのシングルログイン設定を追加しました。"
      redirect_to settings_single_logins_path
    else
      render :action => 'index'
    end
  end

  def destroy
    @single_login.destroy
    flash[:notice] = "#{ERB::Util.h(@single_login.login)}さんへのシングルログイン設定を削除しました。"
    redirect_to settings_single_logins_path
  end

  private
  def find_single_login
    @single_login = current_user.single_logins.find(params[:id])
  end


end
