require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/analytics_controller'

# Re-raise errors caught by the controller.
class Admin::AnalyticsController; def rescue_action(e) raise e end; end

class Admin::AnalyticsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::AnalyticsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
