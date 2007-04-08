class OpenController < ApplicationController
  skip_before_filter :login_required
  layout 'login'

end
