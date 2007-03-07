require File.dirname(__FILE__) + '/../test_helper'

class BugTest < Test::Unit::TestCase
  fixtures :bugs
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_bug_creation
    bug_size = Bug.count
    bug = Bug.create :level => Bug::WARNING, :description => "dummy bug"
    assert_equal bug_size + 1, Bug.count
    
    feed = Feed.create :href => "123", :title => "456", :link => "789"
    feed_bug_size = feed.bugs.size
    feed.bugs << bug
    
    assert_equal feed_bug_size + 1, feed.bugs.size
    
    assert_not_nil bug.feed
    assert_equal bug.feed, feed
    assert !feed.has_error
    assert feed.has_warnings
  end
  
  def test_bug_resolution
    bug = Bug.find(321)
    assert Bug::NEW, bug.status
    bug.resolve
    assert Bug::FIXED, bug.status
    bug = Bug.find(323)
    assert Bug::FIXED, bug.status
  end
  
  def test_send_mail
    bug = Bug.create :level => Bug::WARNING, :description => "dummy bug"
    feed = Feed.create :href => "123", :title => "456", :link => "789"
    feed.bugs << bug
    
    num_deliveries = ActionMailer::Base.deliveries.size
    bug.send_by_mail
    
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size
    assert ActionMailer::Base.deliveries.last.subject.include?("[WARNING]")
    
    num_deliveries = ActionMailer::Base.deliveries.size
    bug = Bug.create :level => Bug::ERROR, :description => "dummy bug"
    feed.bugs << bug
    bug.send_by_mail
    
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size
    assert ActionMailer::Base.deliveries.last.subject.include?("[ERROR]")
  end
  
  def test_error
    bug = Bug.create :level => Bug::ERROR, :description => "dummy bug"
    feed = Feed.create :href => "123", :title => "456", :link => "789"
    feed.bugs << bug
    
    assert Bug.feed_error(feed)
  end
  
  def test_warnings
    bug = Bug.create :level => Bug::WARNING, :description => "dummy bug"
    feed = Feed.create :href => "123", :title => "456", :link => "789"
    feed.bugs << bug
    
    assert_equal 1, Bug.feed_warnings(feed).size
  end
end
