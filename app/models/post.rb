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
  
  def Post.from_google_api(feed)
    
    cache_key = "feed_post_#{feed.id}"
    
    # Get post from cache or generate post if not found
    unless @post = CACHE.get(cache_key)
      # Google Feed APIs requet
      api_key  = "ABQIAAAA9zOhBEt4clOGQ8tTuRG23xROrSfPPZ9VrXnVvSOW6b3RGqWs9BQHv-qS12V8LisjhJ3LXaHei7SmRA"
      base_url = "http://www.google.com/uds/Gfeeds?callback=google.feeds.Feed.RawCompletion&context=0&num=1&hl=en&v=1.0&output=json"
      url = "#{base_url}&key=#{api_key}&q=#{CGI::escape(feed.link)}"

      resp = Net::HTTP.get_response(URI.parse(url))
      begin
        if resp.body =~ /\'Feed could not be loaded\.\'/
          
        else
          data = resp.body.sub!(/^.*\{/, '{').sub!(/\}.*$/, '}')

          # we convert the returned JSON data to native Ruby
          # data structure - a hash
          result = JsonParser.new.parse(data)

          # if the hash has 'Error' as a key, we raise an error
          if result.has_key? 'Error'
            raise "web service error"
          end
    
          @post = Post.new(:title => result['title'], :created_at => result['publishedDate'], :url => result['link'])
    
          if feed.link =~ /http:\/\/api\.flickr\.com/ # Flickr post
            image = result['content'].scan(/(http:\/\/farm.*_.\.jpg)/).to_s
            @post.description = "<a href='#{result['link']}' class='image_link'><img src='#{image.gsub!(/_.\.jpg/,"_t.jpg")}' class='flickr_image'/></a><br/>"
          elsif feed.link =~ /http:\/\/picasaweb\.google\.com/ # Picasa post
            image = result['content'].scan(/(http:\/\/.{3,5}\.google\.com\/image\/.*\.jpg)/).to_s
            @post.description = "<a href='#{result['link']}' class='image_link'><img src='#{image}?imgmax=160&crop=1' width='140px' class='picasa_image'/></a>"
          elsif feed.link =~ /http:\/\/video\.google\.com/ # Google video post
            image = result['content'].scan(/(http:\/\/img\.youtube\.com\/.*\.jpg)/).to_s
            image = result['content'].scan(/(http:\/\/video\.google\.com\/ThumnailServer2.*)\"/).to_s if image.nil? or image.empty?
            @post.description = "<a href='#{result['link']}' class='image_link'><img src='#{image}' class='google_video_image' /></a><br/>"
          else # normal post
            @post.description = result['contentSnippet']
          end
        end
        # Store post in cache for 10 minutes
        CACHE.set(cache_key, @post, 60*10)
      rescue => err
         Bug.raise_feed_bug(feed, "impossible to read feed post: #{err}")
      end
    end
    
    return @post
  end
end
