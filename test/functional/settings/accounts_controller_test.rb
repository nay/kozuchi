require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/accounts_controller'

# Re-raise errors caught by the controller.
class Settings::AccountsController; def rescue_action(e) raise e end; end

class Settings::AccountsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Settings::AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
