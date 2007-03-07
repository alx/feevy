require File.dirname(__FILE__) + '/../test_helper'
require 'feevy_controller'

# Re-raise errors caught by the controller.
class FeevyController; def rescue_action(e) raise e end; end

class FeevyControllerTest < Test::Unit::TestCase
  def setup
    @controller = FeevyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
