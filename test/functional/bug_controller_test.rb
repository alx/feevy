require File.dirname(__FILE__) + '/../test_helper'
require 'bug_controller'

# Re-raise errors caught by the controller.
class BugController; def rescue_action(e) raise e end; end

class BugControllerTest < Test::Unit::TestCase
  def setup
    @controller = BugController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
