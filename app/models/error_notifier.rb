class ErrorNotifier < ActionMailer::Base
  
  def feed_bug(bug)
    @recipients = "myciberia@googlegroups.com"
    @from = "error@feevy.com"
    
    @subject = ""
    if bug.is_warning?
      @subject << "[WARNING] "
    elsif bug.is_error?
      @subject << "[ERROR] "
    end
    @subject << "Feed problem on feevy.com"
    
    @body["error"] = bug.description
    
    unless bug.feed.nil?
      feed = bug.feed
    
      @body["website"] = feed.href
      @body["url"] = feed.link
      @body["feed"] = feed.to_xml
    end
  end
end
