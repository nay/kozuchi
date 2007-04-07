class AssetsController < ApplicationController
  include BookMenues
  layout 'main'
  helper :graph
  before_filter :check_account
  
  before_filter :prepare_date, :load_assets

  def update
    render(:partial => "assets", :layout => false)
  end
  

end
