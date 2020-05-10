class WelcomeController < ApplicationController
  skip_before_action :login_required
    
  def index
    @privacy_policy_setting = PrivacyPolicySetting.new
  end
    
end
