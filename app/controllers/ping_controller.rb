class PingController < ApplicationController
  
  def update
    if true
      render :nothing => true, :status => 503
    else
      feed = Feed.find(params[:id])
      feed.refresh
      render :nothing => true
    end
  end
  
  def list
    
    if true
      render :nothing => true, :status => 503
    else
      # Get master Ping offset or create it if nil
      @ping = Ping.find(:first)
      @ping = Ping.create(:name => "Master Ping", :current_offset => 0) if @ping.nil?
    
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
