class AssetsController < ApplicationController
  include WithCalendar
  layout 'main'
  helper :graph
  menu_group "家計簿"
  menu "資産表"
  before_filter :check_account
  before_filter :load_target_date, :redirect_unless_month, :load_assets

  def index
    @menu_name = "資産表"
  end

end
