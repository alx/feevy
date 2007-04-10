class PingController < ApplicationController
  
  def update
    feed = Feed.find(params[:id])
    feed.refresh
    render :nothing => true
  end
  
  def list
    nb_feeds_in_list = 100
    # Get master Ping offset or create it if nil
    @ping = Ping.find(:first)
    @ping = Ping.create(:name => "Master Ping", :current_offset => 0) if @ping.nil?
    current_offset = @ping.current_offset
    # Check offset, and reset it if greater than feed list size
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
    render :layout => false
  end
end
