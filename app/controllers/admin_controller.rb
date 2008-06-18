class AdminController < ApplicationController

  def index
    require_auth 'admin'
    @pingers = Ping.find(:all)
  end
  
  def feeds
    require_auth 'admin'
    @feeds, @page = Feed.paginate(:all, :page => params[:page])
    @nb_pages = Feed.count
  end
  
  def search_feed
    require_auth 'admin'
    search = "%#{params[:search]}%"
    condition = ["feeds.href LIKE ? OR feeds.title LIKE ? OR feeds.link LIKE ?", search, search, search]
    
    @feeds, @page = Feed.paginate(:all, 
                                  :conditions => condition,
                                  :page => params[:page])        
    @nb_pages = Feed.find(:all,
                          :conditions => condition).size
    render :action => 'feeds'
  end

  def feed_repair
    require_auth 'admin'
    @feeds = Feed.find(:all)
    @bad_format_feeds = @feeds.select{|feed| (not feed.link.nil?) and feed.link !~ /^(http)/ }
    @nil_feeds = @feeds.select{|feed| feed.link.nil?}
    @obvious_feeds = @nil_feeds.select{|feed| feed.href =~ /((feeds\.feedburner\.com)|(rss)|(atom\.xml)|(\/feed\/)|(feeds\/posts\/default))/}
  end
  
  def edit_feed
    require_auth 'admin'
    @feed = Feed.find params[:id]
    if request.post?
      @feed.update_attributes params[:feed]
    end
  end
  
  def update_feed
    require_auth 'admin'
    @feed = Feed.find params[:id]
    @feed.refresh(true)
    render :action => 'edit_feed'
  end
  
  def update_avatar
    require_auth 'admin'
    @feed = Feed.find params[:id]
    @feed.discover_avatar_txt
    render :action => 'edit_feed'
  end
  
  def remove_duplicate_feeds
    require_auth 'admin'
    @duplicates = Feed.remove_duplicates
    flash[:notice] = "#{@duplicates.size} duplicate feeds removed"
    redirect_to :action => 'index'
  end
  
  def merge_duplicates
    require_auth 'admin'
    Feed.merge_duplicates(params[:central], params[:merged])
    flash[:notice] = "Feeds merged"
    redirect_to :action => 'index'
  end
  
  def feed_similar
    @posts = Post.find :all
    @similars = Hash.new
    @posts.each do |post|
      # get post base url
      base_url = post.url.slice(/^(http:\/\/).[^\/]*/)
      unless base_url.nil?
        if @similars.has_key?(base_url)
          if not @similars[base_url].include?(post.feed_id)
            @similars[base_url] << post.feed_id
          end
        else
          @similars[base_url] = [post.feed_id]
        end
      end
    end
    @similars.delete_if { |k, v| v.size == 1 }
  end
  
  def clean_empty_subscription
    require_auth 'admin'
    nb_sub_destroyed = 0
    Subscription.find(:all).each do |sub|
      if sub.feed.nil?
        sub.destroy
        nb_sub_destroyed += 1
      end
      if sub.user.nil?
        sub.destroy
        nb_sub_destroyed += 1
      end
    end
    flash[:notice] = "#{nb_sub_destroyed} empty subscriptions erased"
    redirect_to :action => 'index'
  end
  
  def edit_feed_url
    require_auth 'admin'
    # find feed to modify
    @feed = Feed.find params[:feed][:id]
    # update feed link
    @feed.update_attribute 'link', params[:feed][:link]
    # update title if nil
    @feed.fix_with_rss
    redirect_to :action => 'feed_repair'
  end
  
  def repair_obvious_feeds
    require_auth 'admin'
    @obvious_feeds = Feed.find(:all).select{|feed| feed.link.nil? and feed.href =~ /((feeds\.feedburner\.com)|(rss)|(atom\.xml)|(\/feed\/)|(feeds\/posts\/default))/}
    @obvious_feeds.each do |feed|
      # find feed to modify
      feed.update_attribute 'link', feed.href
      # update title if nil
      feed.fix_with_rss
    end
    redirect_to :action => 'feed_repair'
  end
  
  def remove_feed
    require_auth 'admin'
    @feed = Feed.find params[:feed][:id]
    if @feed
      @feed.destroy
    end
    redirect_to :action => 'feed_repair'
  end
  
  def delete_feed
    require_auth 'admin'
    @headers["Content-Type"] = "text/javascript"
    @feed = Feed.find params[:id]
    if @feed
      @feed.destroy
    end
  end
end