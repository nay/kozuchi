require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/assets_controller'

# Re-raise errors caught by the controller.
class Settings::AssetsController; def rescue_action(e) raise e end; end

class Settings::AssetsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Settings::AssetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
