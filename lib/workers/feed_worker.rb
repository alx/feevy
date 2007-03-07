class FeedWorker < BackgrounDRb::Rails
  
  attr_reader :progress, :feed_count
  attr_accessor :infinite
  
  def do_work(args)
    @infinite = false
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
    @feeds.each {|feed| update(feed)}
  end
  
  def update(feed)
    begin
      Timeout::timeout(@timeout) {
        unless feed.bogus == true
          feed.refresh
        end
      }
    rescue Timeout::Error
      unless feed.nil?
        feed.raise_bug("timeout", Bug::WARNING)
        puts "Time Error on feed #{feed.id}"
      end
    rescue => err
      puts "Error on feed #{feed.id}: #{err}"
    end
    @progress += 1
  end
end