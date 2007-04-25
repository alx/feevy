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
  
  def Post.from_google_api(feed)
    
    cache_key = "feed_post_#{feed.id}"
    
    # Get post from cache or generate post if not found
    unless @post = CACHE.get(cache_key)
      # Google Feed APIs requet
      api_key  = "ABQIAAAA9zOhBEt4clOGQ8tTuRG23xROrSfPPZ9VrXnVvSOW6b3RGqWs9BQHv-qS12V8LisjhJ3LXaHei7SmRA"
      base_url = "http://www.google.com/uds/Gfeeds?callback=google.feeds.Feed.RawCompletion&context=0&num=1&hl=en&v=1.0&output=json"
      url = "#{base_url}&key=#{api_key}&q=#{CGI::escape(feed.link)}"

      resp = Net::HTTP.get_response(URI.parse(url))
      if resp.body.nil?
        Bug.raise_feed_bug(feed, "impossible to read feed post")
      else
        data = resp.body.sub!(/^.*\{/, '{').sub!(/\}.*$/, '}')

        # we convert the returned JSON data to native Ruby
        # data structure - a hash
        #result = JsonParser.new.parse(data, :options => {:surrogate => false})
        result = JsonParser.new.parse(data)

        # if the hash has 'Error' as a key, we raise an error
        if result.has_key? 'Error'
          raise "web service error"
        end
    
        @post = Post.new(:title => result['title'], :created_at => result['publishedDate'], :url => result['link'])
    
        if feed.link =~ /http:\/\/api\.flickr\.com/ # Flickr post
          @post.description = Post.flickr_description(result['content'], result['link'])
        elsif feed.link =~ /http:\/\/picasaweb\.google\.com/ # Picasa post
          @post.description = Post.picasa_description(result['content'], result['link'])
        elsif feed.link =~ /http:\/\/video\.google\.com/ # Google video post
          @post.description = Post.google_video_description(result['content'], result['link'])
        else # normal post
          @post.description = result['contentSnippet']
        end
        CACHE.set(cache_key, @post, 60*3)
      end
    end
    
    return @post
  end
  
  def Post.flickr_description(content, post_url)
    image = content.scan(/(http:\/\/farm.*_.\.jpg)/).to_s
    "<a href='#{post_url}' class='image_link'><img src='#{image.gsub!(/_.\.jpg/,"_t.jpg")}' class='flickr_image'/></a><br/>"
  end
  
  def Post.picasa_description(content, post_url)
    image = content.scan(/(http:\/\/.{3,5}\.google\.com\/image\/.*\.jpg)/).to_s
    "<a href='#{post_url}' class='image_link'><img src='#{image}?imgmax=160&crop=1' width='140px' class='picasa_image'/></a>"
  end
  
  def Post.google_video_description(content, post_url)
    image = content.scan(/(http:\/\/img\.youtube\.com\/.*\.jpg)/).to_s
    image = content.scan(/(http:\/\/video\.google\.com\/ThumnailServer2.*)\"/).to_s if image.nil? or image.empty?
    "<a href='#{post_url}' class='image_link'><img src='#{image}' class='google_video_image' /></a><br/>"
  end
end
