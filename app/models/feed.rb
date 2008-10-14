class Feed < ActiveRecord::Base
  include TextyHelper
  include WillPaginate
  
  cattr_reader :per_page
  @@per_page = 200

  # Stablish the rich join model for users and subscribed feeds
  # Right now, the only attribute of the "user has many feeds"
  # is the avatar URL.

  has_many :subscriptions
  has_many :users, :through => :subscriptions
  has_many :posts, :order => 'created_at DESC'
  has_one :latest_post, :class_name => 'Post', :order => 'id DESC'
  belongs_to :avatar

  validates_presence_of :link, :title, :href
  
  before_destroy :destroy_relationship
  
  # Discover avatar.txt file to update avatar
  def Feed.update_avatars
    Feed.find(:all).each { |feed| feed.discover_avatar_txt }
  end

  def Feed.create_from_blog(input_url)
    # clean up the url
    begin
      logger.debug "input_url: #{input_url}"
      input_url = Feed.normalize_url(input_url)
    rescue => err
      logger.debug "error on input_url: #{err.class}: #{err.message}#$/\n#{err.backtrace.join($/)}"
    end
    
    return nil if input_url.nil?
      
    if Rfeedfinder::isFeed?(input_url)
      return Feed.create_feed(feed_url=input_url)
    else
      return Feed.create_feed(web_url=input_url)
    end
  end
  
  def Feed.is_opml?(opml)
    doc = Hpricot(open(opml))
    return (doc/:opml)
  end
  
  def Feed.create_from_opml(opml)
    feeds = []
    doc = Hpricot(open(opml))
    (doc/"outline").each do |url|
      logger.debug "xml: #{url[:xmlurl]} - html: #{url[:htmlurl]}"
      feed = nil
      feed = create_feed(web_url=url[:htmlurl], feed_url=url[:xmlurl])
      feeds << feed unless feed.nil?
    end
    return feeds
  end
  
  def Feed.create_feed(web_url=nil, feed_url=nil)
    
    return nil if web_url.nil? and fedd_url.nil?
    
    # If it's a feed url
    if !feed_url.nil? and web_url.nil?
      # Check existing feed with this feed url
      feed = Feed.find :first, :conditions => ["link LIKE ?", feed_url]
      logger.debug("feed found") if !feed.nil?
      return feed if !feed.nil?
      feeding = Rfeedreader.read_first(feed_url)
      web_url = feeding.link
      return nil if web_url.nil? or web_url.empty?
      
    # If it's a blog url
    elsif !web_url.nil? and feed_url.nil?
      # Check existing feed with this web url
      feed = Feed.find :first, :conditions => ["href LIKE ?", web_url]
      logger.debug("feed found") if !feed.nil?
      return feed if !feed.nil?
      feeding = Rfeedreader.read_first(web_url)
      feed_url = feeding.feed_url
      return nil if feed_url.nil? or feed_url.empty?
      
    # If both url are provided
    else
      feed = Feed.find :first, :conditions => ["href LIKE ? or link LIKE ?", web_url, feed_url]
      return feed if !feed.nil?
      feeding = Rfeedreader.read_first(feed_url)
    end
    
    return nil if feeding.nil? or web_url.nil? or feed_url.nil?
    
    feed = Feed.create(:href => web_url, 
                       :link => feed_url, 
                       :title => feeding.title,
                       :avatar_id => 1)
                       
    # Add new post to feed if possible
    if !feeding.entries.nil? and !feeding.entries[0].nil?
      entry = feeding.entries[0]
      Post.create(:url => entry.link, 
                  :title => entry.title, 
                  :description => entry.description, 
                  :feed_id => feed.id)
    end
                 
    # Discover avatar
    feed.discover_avatar_txt
      
    return feed
  end
  
  def refresh(forced=false)
    begin
      # Get first item
      Timeout::timeout(30) do
        entry = Rfeedreader.read_first(link).entries[0]
        
        if !entry.nil? and !entry.link.nil? and (forced or latest_post.nil? or entry.link != latest_post.url)        
          # Save new post
          Post.create(:url => entry.link, 
                      :title => entry.title, 
                      :description => entry.description, 
                      :feed_id => id)
        end
      end
    rescue Timeout::Error
    rescue => err
    end
  end
  
  # Return the rss item link
  def read_link(item)
    link = item.search("link:first")
    unless link.nil?
      post_url = link.text
      post_url = link.to_s.scan(/href=['"]?([^'"]*)['" ]/).to_s if (post_url.nil? or post_url.empty?)
      return post_url
    else
      return nil
    end
  end
  
  def discover_avatar_txt
    begin
      #open avatar url
      Timeout::timeout(30) do
        # if self.href =~ /lacomunidad\.elpais\.com\/.*/
        #   elpais_user = self.href.scan(/^.*\.elpais\.com\/(.[^\/]*)/)[0]
        #   avatar = Avatar.create(:name => elpais_user, 
        #                          :url => "http://lacomunidad.elpais.com/userfiles/#{elpais_user}/avatar48x48.png")
        #   self.update_attributes(:avatar_id => avatar.id, :avatar_locked => true) unless avatar.nil?
        # else
          avatar_link = open(URI.join(self.href, "avatar.txt").to_s)
          logger.debug "avatar link: #{avatar_link}"
          
          unless avatar_link.nil?
            avatar_url = avatar_link.readline.strip
            avatar_link.close

            logger.debug "avatar_url #{avatar_url}"

            if (not avatar_url.blank?) and (avatar_url =~ /^http:\/\//)
              tempfile = Tempfile.new('tmp')
              tempfile.write open(avatar_url).read
              tempfile.flush
              tempfile.close

              # Guess file format
              md = avatar_url.match /\.([^.]+)\z/
              format = md ? md[1].downcase : nil

              logger.debug "format: #{format}"

              unless format.nil?
                avatar = Avatar.create_from_file(tempfile, format.strip)
                self.update_attributes(:avatar_id => avatar.id, :avatar_locked => true) unless avatar.nil?
              end
            end
          # end
        end
      end
    rescue Timeout::Error
      puts "Timeout on this feed"
    rescue
      self.update_attribute :avatar_locked, false
      return nil
    end
  end
  
  # Open website file
  def open_url_file(test=false)
    open_file(self.href, test)
  end
  
  # Open rss/atom feed filr
  def open_feed_file(test=false)
    open_file(self.link, test)
  end
  
  def open_file(file_url, test=false)
    begin    
      # Open url
      file = open(file_url)
      
      # Set feed charset depending on the file
      charset = Feed.read_encoding(file)
      self.update_attribute(:charset, charset) unless self.charset == charset
      
      return file
    rescue => error
      return nil
    end
  end
  
  def fix_with_rss
    begin
      file = open(self.link)
      unless file.nil?
        file.rewind
        rss = SimpleRSS.parse file
        file.close
    
        self.update_attributes :title => rss.channel.title,
                              :href => rss.channel.link
      end
    rescue => err
    end
  end
  
  def Feed.remove_duplicates
    deleted_feeds = []
    @feeds = Feed.find(:all)
    @feeds.each do |feed|
      logger.info "Feed: #{feed.link}"
      @duplicates = @feeds.select{|duplicate| duplicate.id != feed.id and duplicate.link == feed.link}
      @duplicates.each do |duplicate|
        logger.info "Duplicate found: #{duplicate.id}"
        duplicate.subscriptions.each {|sub| sub.update_attribute(:feed_id, feed.id)}
        duplicate.posts.each {|post| post.update_attribute(:feed_id, feed.id)}
        @feeds.delete(duplicate)
        deleted_feeds << duplicate.link
        duplicate.destroy
      end
      @feeds.delete(feed)
    end
    logger.debug "delete feed size: #{deleted_feeds.size}"
  end
  
  # [*"www.a".."www.z"].each {|char| Feed.remove_regexp_duplicates(char)}
  # [*"www.0".."www.9"].each {|char| Feed.remove_regexp_duplicates(char)}
  # [*"a".."z"].each {|char| Feed.remove_regexp_duplicates(char)}
  # [*"0".."9"].each {|char| Feed.remove_regexp_duplicates(char)}
  def Feed.remove_regexp_duplicates(char)
    @feeds = Feed.find(:all, :order => "created_at DESC", :conditions => [ "link REGEXP ?", "^http:\\/\\/[[:<:]]#{char}[[:>:]].*$"])
    @feeds.each do |feed|
      @duplicates = @feeds.select{|testing| testing.id != feed.id and testing.link.downcase == feed.link.downcase}
      @duplicates.each do |duplicate|
        puts "Duplicate found: #{duplicate.id} - #{duplicate.link}"
    	unless duplicate.subscriptions.nil? 
    	duplicate.subscriptions.each {|sub| sub.update_attribute(:feed_id, feed.id)}
    	end
    	unless duplicate.posts.nil?
    	duplicate.posts.each {|post| post.update_attribute(:feed_id, feed.id)}
    	end
        @feeds.delete(duplicate)
        duplicate.destroy
      end
      @feeds.delete(feed)
    end
  end
  
  def Feed.merge_duplicates(central_feed_id, merged_feed_id)
    @central_feed = Feed.find central_feed_id
    @merged_feed = Feed.find merged_feed_id
    # Migrate subscriptions
    @merged_feed.subscriptions.each {|sub| sub.update_attribute(:feed_id, @central_feed.id)}
    # Migrate posts
    @merged_feed.posts.each {|post| post.update_attribute(:feed_id, @central_feed.id)}
    # Delete merged feed
    @merged_feed.destroy
  end
  
  def Feed.normalize_url(url)
    if url.kind_of?(URI)
      url = url.to_s
    end
    if url.blank?
      return nil
    end
    normalized_url = CGI.unescape(url.strip)

    # if a url begins with the '/' character, it only makes sense that they
    # meant to be using a file:// url.  Fix it for them.
    if normalized_url.length > 0 && normalized_url[0..0] == "/"
      normalized_url = "file://" + normalized_url
    end

    # if a url begins with a drive letter followed by a colon, we're looking at
    # a file:// url.  Fix it for them.
    if normalized_url.length > 0 &&
        normalized_url.scan(/^[a-zA-Z]:[\\\/]/).size > 0
      normalized_url = "file:///" + normalized_url
    end

    # if a url begins with javascript:, it's quite possibly an attempt at
    # doing something malicious.  Let's keep that from getting anywhere,
    # shall we?
    if (normalized_url.downcase =~ /javascript:/) != nil
      return "#"
    end

    # deal with all of the many ugly possibilities involved in the rss:
    # and feed: pseudo-protocols (incidentally, whose crazy idea was this
    # mess?)
    normalized_url.gsub!(/^http:\/*(feed:\/*)?/i, "http://")
    normalized_url.gsub!(/^http:\/*(rss:\/*)?/i, "http://")
    normalized_url.gsub!(/^feed:\/*(http:\/*)?/i, "http://")
    normalized_url.gsub!(/^rss:\/*(http:\/*)?/i, "http://")
    normalized_url.gsub!(/^file:\/*/i, "file:///")
    normalized_url.gsub!(/^https:\/*/i, "https://")
    # fix (very) bad urls (usually of the user-entered sort)
    normalized_url.gsub!(/^http:\/*(http:\/*)*/i, "http://")

    if (normalized_url =~ /^file:/i) == 0
      # Adjust windows-style urls
      normalized_url.gsub!(/^file:\/\/\/([a-zA-Z])\|/i, 'file:///\1:')
      normalized_url.gsub!(/\\/, '/')
    else
      if (normalized_url =~ /^https?:\/\//i) == nil
        normalized_url = "http://" + normalized_url
      end
      if normalized_url == "http://"
        return nil
      end
      begin
        scheme, host_part, path =
          normalized_url.scan(/^(https?):\/\/([^\/]+)\/(.*)/i).flatten
        if scheme != nil && host_part != nil && path != nil
          scheme = scheme.downcase
          if FeedTools::UriHelper.idn_enabled?
            host_part =
              IDN::Idna.toASCII(host_part)
          end
          new_path = ""
          for index in 0...path.size
            if path[index] <= 32 || path[index] >= 126
              new_path << ("%" + path[index].to_s(16).upcase)
            else
              new_path << path[index..index]
            end
          end
          path = new_path
          normalized_url = scheme + "://" + host_part + "/" + path
        end
      rescue Object
      end
      begin
        feed_uri = URI.parse(normalized_url)
        if feed_uri.scheme == nil
          feed_uri.scheme = "http"
        end
        if feed_uri.path.blank?
          feed_uri.path = "/"
        end
        if (feed_uri.path =~ /^[\/]+/) == 0
          feed_uri.path.gsub!(/^[\/]+/, "/")
        end
        while (feed_uri.path =~ /^\/\.\./)
          feed_uri.path.gsub!(/^\/\.\./, "")
        end
        if feed_uri.path.blank?
          feed_uri.path = "/"
        end
        feed_uri.host.downcase!
        normalized_url = feed_uri.to_s
      rescue URI::InvalidURIError
      end
    end

    # We can't do a proper set of escaping, so this will
    # have to do.
    normalized_url.gsub!(/%20/, " ")
    normalized_url.gsub!(/ /, "%20")

    return normalized_url
  end
    
  private
  def destroy_relationship
    Post.destroy_all "feed_id = #{self.id}"
    Subscription.destroy_all "feed_id = #{self.id}"
  end
end
