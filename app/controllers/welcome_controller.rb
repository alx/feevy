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
    
    # Get english rss from cache or from net
    unless @rss_english = CACHE.get("rss_english")
      begin
        @rss_english = SimpleRSS.parse open('http://blog.feevy.com/feed/')
        CACHE.set("rss_english", @rss_english, 60*60)
      rescue
        @rss_english = []
      end
    end
    
    # Get spanish rss from cache or from net
    unless @rss_spanish = CACHE.get("rss_spanish")
      begin
        @rss_spanish = SimpleRSS.parse open('http://bitacora.feevy.com/feed/')
        CACHE.set("rss_spanish", @rss_english, 60*60)
      rescue
        @rss_spanish = []
      end
    end
    @nb_users = User.count
    @nb_feeds = Feed.count
  end
  
  def coming_soon
    render :layout => false
  end
  
  def dot_file
    @subscriptions = Subscription.find(:all)
    render :layout => false
  end
end
