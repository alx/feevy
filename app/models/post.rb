class Post < ActiveRecord::Base
  
  belongs_to :feed
  
  validates_presence_of :url
  
  def Post.remove_orphelin
    Post.find(:all).each do |post|
      if post.feed.nil?
        post.destroy
      end
    end
  end
end
