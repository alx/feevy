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
    
    unless @feeds = CACHE.get("welcome_feeds")
      @feeds = ""
      Feed.find(:all, :limit => 20, :order => "created_at DESC", :conditions => ["title IS NOT NULL"]).each do |feed|
        @feeds << "<a href='#{feed.href}'>#{feed.title}</a><br/>"
      end
      CACHE.set("welcome_feeds", @feeds, 60*60)
    end
    
    delay = 30
    
    # Get english rss from cache or from net
    unless @rss_english = CACHE.get("rss_english")
      begin
        Timeout::timeout(delay) {
          @rss_english = show_post Hpricot(open('http://blog.feevy.com/feed/')).search("item").first
        }
      rescue Timeout::Error
        logger.debug "Timeout while reading english blog feed: #{err}"
        @rss_english = []
      rescue => err
        logger.debug "Error while reading english blog feed: #{err}"
        @rss_english = []
      end
    end
    
    # Get spanish rss from cache or from net
    unless @rss_spanish = CACHE.get("rss_spanish")
      begin
        Timeout::timeout(delay) {
          @rss_spanish = show_post Hpricot(open('http://bitacora.feevy.com/feed/')).search("item").first
        }
      rescue Timeout::Error
        logger.debug "Timeout while reading spanish blog feed: #{err}"
        @rss_spanish = []
      rescue => err
        logger.debug "Error while reading spanish blog feed: #{err}"
        @rss_spanish = []
      end
    end
    
    CACHE.set("rss_spanish", @rss_spanish, 60*60)
    CACHE.set("rss_english", @rss_english, 60*60)
    
    unless @nb_users = CACHE.get("nb_users")
      @nb_users = User.count
      CACHE.set("nb_users", @nb_users, 60*60)
    end
    
    unless @nb_feeds = CACHE.get("nb_feeds")
      @nb_feeds = Feed.count
      CACHE.set("nb_feeds", @nb_feeds, 60*60)
    end
  end
  
  def coming_soon
    render :layout => false
  end
  
  def dot_file
    @subscriptions = Subscription.find(:all)
    render :layout => false
  end
  
  protected
  
  def show_post(item)
    pubDate = Time.parse((item/"pubDate").inner_text)
    post = "<p>#{pubDate.day}.#{pubDate.month}.#{pubDate.year}<p><br/>"
    post << "<h4>#{(item/"title").inner_text}</h4><br/>"
    post << "<h5>#{(item/"description").inner_text.gsub(" [...]", "...")}"
    post << "<a href='#{(item/"link").inner_text}'>continue</a></h5><br/><br/>"
    return post
  end
end
