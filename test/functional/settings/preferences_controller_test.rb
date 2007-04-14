require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/preferences_controller'

# Re-raise errors caught by the controller.
class Settings::PreferencesController; def rescue_action(e) raise e end; end

class Settings::PreferencesControllerTest < Test::Unit::TestCase
  def setup
    @controller = Settings::PreferencesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
