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
end
