require File.dirname(__FILE__) + '/../test_helper'
require 'settlements_controller'

# Re-raise errors caught by the controller.
class SettlementsController; def rescue_action(e) raise e end; end

class SettlementsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SettlementsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
