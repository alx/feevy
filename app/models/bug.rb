class Bug < ActiveRecord::Base
  belongs_to :feed
  
  # Bug Severity Level
  INFO = 0
  WARNING = 1
  ERROR = 2
  
  # Bug status
  NEW = 0
  FIXED = 1
  
  def Bug.feed_error(feed)
    Bug.find :first, :conditions => ["feed_id = ? AND level = ? AND status = ?", feed.id, Bug::ERROR, Bug::NEW]
  end
  
  def Bug.feed_warnings(feed)
    Bug.find :all, :conditions => ["feed_id = ? AND level = ? AND status = ?", feed.id, Bug::WARNING, Bug::NEW]
  end
  
  def Bug.resolve_feed(feed)
    @bugs = Bug.find :all, :conditions => ["feed_id = ? AND status = ?", feed.id, Bug::NEW]
    @bugs.each {|bug| bug.resolve}
  end
  
  # Create a new bug with default level of Bug::ERROR
  def Bug.raise_feed_bug(feed, error, level=Bug::ERROR)
    logger.debug error
    level = Bug::ERROR if level.nil?
    Bug.create(:level => level, 
               :description => error,
               :feed_id => feed.id).send_by_mail
  end
  
  def resolve
    self.update_attribute :status, Bug::FIXED
  end
  
  def is_warning?
    return self.level.eql?(Bug::WARNING)
  end
  
  def is_error?
    return self.level.eql?(Bug::ERROR)
  end
  
  # Send a mail with the bug
  # Keep it like this to send bugs from different origins in the future (Feed, User, Avatar, ...)
  def send_by_mail
    ErrorNotifier::deliver_feed_bug(self)
  end
end
