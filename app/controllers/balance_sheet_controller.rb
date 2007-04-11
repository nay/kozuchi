class BalanceSheetController < ApplicationController
  layout 'main'
  
  before_filter :prepare_date, :load_user, :load_assets

  def update
    render(:partial => "balance_sheet", :layout => false)
  end
  
end
