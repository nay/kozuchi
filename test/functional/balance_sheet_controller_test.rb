require File.dirname(__FILE__) + '/../test_helper'
require 'balance_sheet_controller'

# Re-raise errors caught by the controller.
class BalanceSheetController; def rescue_action(e) raise e end; end

class BalanceSheetControllerTest < Test::Unit::TestCase
  def setup
    @controller = BalanceSheetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
