# カスタマイズ （個人的好みによる設定） 
class Settings::PreferencesController < ApplicationController
  before_filter :require_post, :only => [:update]
  layout 'main'
  before_filter {|controller| controller.menu_group = "高度な設定"}

  def index
    @preferences = @user.preferences
  end
  
  def update
    preferences = Preferences.get(@user.id)
    preferences.attributes = params[:preferences]
    begin
      preferences.save!
      @user.preferences(true)
      flash_notice("更新しました。")
    rescue
      flash_validation_errors(preferences)
    end
    redirect_to(:action => 'index')
  end

end
