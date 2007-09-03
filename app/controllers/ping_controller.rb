class PingController < ApplicationController
  
  def update
    feed = Feed.find(params[:id])
    feed.refresh
    render :nothing => true
  end
  
  def update_feed
    pinger = Ping.find(:first, :conditions => ["hash like ?", params[:pinger_hash]]))
    
    unless pinger.nil?
      # Create new post
      Post.create(:url => params[:post_link], 
                  :title => params[:post_title], 
                  :description => params[:post_description], 
                  :feed_id => params[:id])
    
      # Delete old posts
      @posts = Post.find(:all, :conditions => "feed_id = #{params[:id]}", :order => "created_on DESC")
      @posts.delete_at(0)
      @posts.each {|post|post.destroy}
    end
    
    render :nothing => true
  end
  
  def list
    # Get master Ping offset or create it if nil
    @ping = Ping.find(:first, :conditions => ["name like ?", "Master Ping"])
    @ping = Ping.create(:name => "Master Ping", :current_offset => 0) if @ping.nil?
    
    # Get user pinger id for satistic purpose
    pinger_name = params[:id]
    if !pinger_name.nil? or !pinger_name.empty?
      unless @pinger = Ping.find(:first, :conditions => ["name = ?", pinger_name])
        @pinger = Ping.create(:name => pinger_name, :total_count => 1)
      end
      @pinger.update_attribute :total_count, @pinger.total_count + 1
    # If pinger has not specified ID, declare it as unknown
    else
      unless @pinger = Ping.find(:first, :conditions => ["name = ?", "unknown"])
        @pinger = Ping.create(:name => "unknown")
      end
      @pinger.update_attribute :total_count, @pinger.total_count + 1
    end
    
    # If ping server is locked, tell client to wait
    if @ping.lock == 1 then
      render :layout => false, :status => 503
    else
      @ping.update_attribute("lock", 1)
      current_offset = @ping.current_offset
      # Check offset, and reset it if greater than feed list size
    
      nb_feeds_in_list = 100
      new_offset = current_offset + nb_feeds_in_list
      if new_offset > Feed.count
        @ping.update_attribute("current_offset", 0)
      else
        @ping.update_attribute("current_offset", new_offset)
      end
    
      # Get list of feeds to send to client, depending on master ping offset
      @feeds = Feed.find(:all, :limit => nb_feeds_in_list, :offset => current_offset)
      @feeds = Feed.find(:all, :conditions => ["feeds.id in (?)", @feeds], :include => :latest_post, :order => 'feeds.id, posts.created_at')
      @feeds.delete_if {|feed| feed.link.nil? or feed.latest_post.nil? }
      @ping.update_attribute("lock", 0)
      render :layout => false
    end
  end
  
  def unlock_master_ping
    redirect_to :action => "unlock_ping", :id => 1
  end
  
  def unlock_ping
    @ping = Ping.find(params[:id])
    @ping.update_attribute("lock", 0) if @ping.lock == 1
    render :nothing => true
  end
end
