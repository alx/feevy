class RemoveDuplicateFeeds < ActiveRecord::Migration
  def self.up
    Feed.find(:all).each do |feed|
      @duplicates = Feed.find(:all, :conditions => ["id != ? AND href = ?", feed.id, feed.href])
      @duplicates.each do |duplicate|
        Subscription.find(:all, :conditions => ["feed_id = ?", duplicate.id]).each {|sub| sub.update_attribute :feed_id, feed.id}
        Post.find(:all, :conditions => ["feed_id = ?", duplicate.id]).each {|post| post.update_attribute :feed_id, feed.id}
        duplicate.destroy
      end
    end
    
    Post.find(:all).each do |post|
      @duplicates = Post.find(:all, :conditions => ["id != ? AND url = ?", post.id, post.url])
      @duplicates.each do |duplicate|
        duplicate.destroy
      end
    end
  end

  def self.down
  end
end
