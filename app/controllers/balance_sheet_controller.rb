class BalanceSheetController < ApplicationController
  include WithCalendar
  layout 'main'
  
  before_filter :load_target_date, :redirect_unless_month, :load_assets
  
  def index
    @menu_name = "貸借対照表"
  end
  
end
