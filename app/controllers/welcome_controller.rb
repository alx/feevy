class WelcomeController < ApplicationController
  
  def index
    redirect_to :action => "welcome"
  end
  
  def terms
  end
  
  def faq
  end
  
  def privacy
  end
  
  def welcome
    @feeds = Feed.find(:all, :limit => 20, :order => "created_at DESC")
    begin
      @rss = SimpleRSS.parse open('http://blog.feevy.com/feed/')
    rescue
      @rss = []
    end
    @nb_users = User.count
  end
  
  def coming_soon
    render :layout => false
  end
  
  def dot_file
    now = DateTime::now()
    # Generate cache_key
    cache_key = "dot_file_#{now.yday()}_#{now.year()}"

    # Get entries from cache or generate entries if not found
    unless @subscriptions = CACHE.get(cache_key)
      @subscriptions = Subscription.find(:all)
      @subscriptions.delete_if do |sub|
        sub.user_id.nil? or sub.feed_id.nil? or (sub.user.subscriptions.size == 1 and sub.feed.subscriptions.size == 1)
      end
      CACHE.set(cache_key, @subscriptions, 60*60*24)
    end
    render :layout => false
  end
end
