class FeedUpdateWorker < BackgrounDRb::Rails
  
  attr_reader :progress, :feed_count
  attr_accessor :infinite
  
  def do_work(args)
    @infinite = false
    @progress = 0
    @timeout = 30
    @feeds = Feed.find(:all)
    @feed_count = @feeds.size
    @feeds.each {|feed| update(feed)}
    while @infinite == true
      @progress = 0
      @feeds.each {|feed| update(feed)}
    end
  end
  
  def update(feed)
    begin
      Timeout::timeout(@timeout) {
        feed.refresh(true) unless feed.bogus == true
      }
    rescue Timeout::Error
      unless feed.nil?
        feed.raise_bug("timeout", Bug::WARNING)
        @logger.info "Timeout on feed ##{feed.id}: #{feed.link}"
      end
    end
    @progress += 1
  end
end