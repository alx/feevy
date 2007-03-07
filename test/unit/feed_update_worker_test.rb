require File.dirname(__FILE__) + '/../test_helper'
require "#{RAILS_ROOT}/vendor/plugins/backgroundrb/backgroundrb.rb"
require "#{RAILS_ROOT}/lib/workers/feed_update_worker"
require 'drb'

class FeedUpdateWorkerTest < Test::Unit::TestCase

  # Replace this with your real tests.
  def test_truth
    assert FeedUpdateWorker.included_modules.include?(DRbUndumped)
  end
end
