class Post < ActiveRecord::Base
  
  belongs_to :feed
  
  validates_presence_of :url
  
  after_create :unique_per_feed
  
  def Post.remove_orphelin
    Post.find(:all).each do |post|
      if post.feed.nil?
        post.destroy
      end
    end
  end
  
  def unique_per_feed
    Post.find(:all, :conditions => ["id != ? AND feed_id = ?", id, feed_id]).each {|object| object.destroy}
  end
end
