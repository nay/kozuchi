# カスタマイズ （個人的好みによる設定）
class Settings::PreferencesController < ApplicationController
  menu_group "設定"
  menu "カスタマイズ"

  before_action :find_preferences

  def show
  end
  
  def update
    @preferences.attributes = preferences_params
    if @preferences.save
      flash_notice("更新しました。")
      redirect_to :action => 'show'
    else
      current_user.reload
      render :action => :show
    end
  end

  private
  def preferences_params
    params.require(:preferences).permit(:color, :business_use, :bookkeeping_style)
  end

  def find_preferences
    @preferences = current_user.preferences
    raise IllegalStateError, "No preference for user #{current_user.id}" unless @preferences
  end

end
