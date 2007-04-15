require File.dirname(__FILE__) + '/../test_helper'
require 'daily_booking_controller'

# Re-raise errors caught by the controller.
class DailyBookingController; def rescue_action(e) raise e end; end

class DailyBookingControllerTest < Test::Unit::TestCase
  def setup
    @controller = DailyBookingController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
