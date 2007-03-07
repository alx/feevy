class LinkifyPostDescription < ActiveRecord::Migration
  def self.up
    Post.find(:all).each do |post|
      post.update_attribute :description, post.description.gsub(/((https?:\/\/)?www\.[^\s]*)/, '[<a href=\'\1\'>link</a>]')
    end
  end

  def self.down
  end
end
