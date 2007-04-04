class FeedWorker < BackgrounDRb::Rails
  
  attr_reader :progress, :feed_count
  attr_accessor :infinite
  
  def do_work(args)
    @infinite = true
    @timeout = 30
    process_all_feeds
    while @infinite
      process_all_feeds
    end
  end
  
  def process_all_feeds()
    @progress = 0
    @feeds = Feed.find(:all, :order => 'RAND()')
    @feed_count = @feeds.size
    @feeds.each do |feed|
      begin
        Timeout::timeout(@timeout) { feed.refresh }
      rescue Timeout::Error
      rescue
      end
      @progress += 1
    end
  end
end