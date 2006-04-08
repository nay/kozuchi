require File.dirname(__FILE__) + '/../test_helper'
require 'book_controller'

# Re-raise errors caught by the controller.
class BookController; def rescue_action(e) raise e end; end

class BookControllerTest < Test::Unit::TestCase
  def setup
    @controller = BookController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
