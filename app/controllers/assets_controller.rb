class AssetsController < ApplicationController
  layout 'main'
  helper :graph
  before_filter :load_user, :check_account
  
  before_filter :prepare_date, :load_assets

  def update
    render(:partial => "assets", :layout => false)
  end
  

end
