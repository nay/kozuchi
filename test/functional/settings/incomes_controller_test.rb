require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/incomes_controller'

# Re-raise errors caught by the controller.
class Settings::IncomesController; def rescue_action(e) raise e end; end

class Settings::IncomesControllerTest < Test::Unit::TestCase
  def setup
    @controller = Settings::IncomesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
