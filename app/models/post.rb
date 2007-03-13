class Post < ActiveRecord::Base
  include TextyHelper
  
  belongs_to :feed
  
  validates_presence_of :url
  validates_uniqueness_of :url
  
  def Post.remove_orphelin
    Post.find(:all).each do |post|
      if post.feed.nil?
        post.destroy
      end
    end
  end
  
  def Post.format_title(title, charset='utf-8')
    clean(convertEncoding(title, charset)).downcase
  end
  
  def Post.format_description(description, charset='utf-8')
    description = HTMLEntities.decode_entities(description) if description.include? "&lt;"
    description = clean(convertEncoding(description, charset), 200) unless description.blank?
    description.gsub!(/((https?:\/\/)?www\.[^\s]*)/, '[<a href=\'\1\'>link</a>]') unless description.blank?
    description.strip
  end
  
  def Post.flickr_description(item, post_url)
    logger.debug "flickr item: #{item.to_s}"
    image = item.search("media:thumbnail").to_s.scan(/url=['"]?([^'"]*)['" ]/).to_s
    logger.debug "flickr image1: #{image}"
    image = item.search("content|description").text.scan(/(http:\/\/farm.*_.\.jpg)/).to_s if image.nil? or image.empty?
    logger.debug "flickr image2: #{image}"
    "<a href='#{post_url}' class='image_link'><img src='#{image.gsub!(/_.\.jpg/,"_t.jpg")}' class='flickr_image'/></a><br/>"
  end
  
  def Post.picasa_description(item, post_url)
    image = item.search("media:thumbnail").to_s.scan(/url=['"]?([^'"]*)['" ]/).to_s
    "<a href='#{post_url}' class='image_link'><img src='#{image}' class='picasa_image'/></a>"
  end
  
  def Post.google_video_description(item, post_url)
    # get url for thumbnail and remove URL encoding
    image = item.search("media:thumbnail").to_s.scan(/url=['"]?([^'"]*)['" ]/).to_s.gsub(/&amp;/, '&')
    logger.debug "google video: #{image}"
    "<a href='#{post_url}' class='image_link'><img src='#{image}' class='google_video_image' width='160px' height='160px'/></a><br/>"
  end
end
