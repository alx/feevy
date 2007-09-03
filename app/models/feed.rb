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
  has_many :bugs
  has_many :posts, :order => 'created_at DESC'
  has_one :latest_post, :class_name => 'Post', :order => 'id DESC'
  belongs_to :avatar

  validates_presence_of :link, :title, :href
  
  before_destroy :destroy_relationship
  
  # Discover avatar.txt file to update avatar
  def Feed.update_avatars
    Feed.find(:all).each { |feed| 
      unless feed.is_bogus?
        logger.info "+++ Refresh avatar: #{feed.href}"
        feed.discover_avatar_txt
      else
        logger.info "--- Not refreshing avatar: #{feed.href}"
      end
    }
  end

  def Feed.create_from_blog(input_url)
    # clean up the url
    begin
      logger.debug "input_url: #{input_url}"
      input_url = self.normalize_url(input_url)
    rescue => err
      logger.debug "error on input_url: #{err.class}: #{err.message}#$/\n#{err.backtrace.join($/)}"
    end
    
    return nil if input_url.nil?
      
    if Rfeedfinder::isFeed?(input_url)
      logger.debug "is_rss"
      # Client send rss url
      feed = self.create_from_rss(input_url)
    else
      feed = self.create_from_webpage(input_url)
    end
    return feed
  end
  
  def Feed.is_opml?(url)
    url =~ /\.opml$/
  end
  
  def Feed.create_from_opml(opml)
    doc = Hpricot(open(opml))
    (doc/"outline[@htmlurl]").each do |url|
      logger.debug "#{url.attributes['htmlurl']}"
      Feed.create_from_url url.attributes['htmlurl']
    end
  end
  
  def Feed.create_from_webpage(input_url)
    # find existing feed with same webpage url
    feed = Feed.find :first, :conditions => ["href LIKE ?", input_url]
    
    if feed.nil?
      begin
        feeding = Rfeedreader.read_first(input_url)
        # find existing feed with same feed url
        if Feed.find(:all, :conditions => ["link LIKE ?", feeding.feed_url]).empty?
          # Create new Feed
          feed = Feed.create(:href => input_url, 
                             :link => feeding.feed_url, 
                             :title => feeding.title,
                             :avatar_id => 1)
        
          # Add new post to feed
          entry = feeding.entries[0]
          Post.new(:url => entry.link, 
                   :title => entry.title, 
                   :description => entry.description, 
                   :feed_id => feed.id)
                   
          # Discover avatar
          feed.discover_avatar_txt
        end
      rescue => error
        logger.error "Error while creating a feed from blog: #{error.message}"
        return error
      end
    end
    return feed
  end
  
  def Feed.create_from_rss(input_url)
    feeding = Rfeedreader.read_first(input_url)
  
    # Register new blog if href has been found
    if !feeding.link.nil?
      feed = Feed.find :first, :conditions => ["link LIKE ?", feeding.link]
      if feed.nil?
        begin
        
          feed = Feed.create(:href => feeding.link, 
                             :link => input_url, 
                             :title => feeding.title, 
                             :avatar_id => 1)
                             
          # Add new post to feed
          entry = feeding.entries[0]
          Post.new(:url => entry.link, 
                   :title => entry.title, 
                   :description => entry.description, 
                   :feed_id => feed.id)
                   
          # Discover avatar
          feed.discover_avatar_txt
        rescue => error
          logger.error "Error while creating a feed from rss: #{error.message}"
          return error
        end
      end
    end
    return feed
  end
  
  def has_error
    return self.is_bogus == 1 ? true : false
  end
  
  alias is_bogus? has_error
  alias bogus has_error
  
  def has_warnings
    return self.is_warning == 1 ? true : false
  end
  
  def refresh(forced=false)
    unless self.is_bogus?
      begin
        # Get first item
        Timeout::timeout(30) do
          entry = Rfeedreader.read_first(input_url).entries[0]
          
          unless entry.nil?
            # get item url
            post_url = entry.url
            # built Post from first item if different url
            if !entry.url.nil? and (forced or latest_post.nil? or entry.url != latest_post.url)
              # Delete existing post if forced update
              if forced == true
                post = Post.find(:first, :conditions => ["url LIKE ? AND feed_id = ?", post_url, self.id])
                post.destroy unless post.nil?
              end
              # Save new post
              Post.create(:url => entry.link, 
                          :title => entry.title, 
                          :description => entry.description, 
                          :feed_id => id)
            end
          end
        end
      rescue Timeout::Error
        Bug.raise_feed_bug(self, "timeout", Bug::WARNING)
      rescue => err
        Bug.raise_feed_bug(self, err) unless self.is_bogus?
      end
    end
  end
  
  # Return true if feed is a flickr feed
  def is_flickr?
    link =~ /http:\/\/api\.flickr\.com/
  end
  
  # Return true if feed is a picasa feed
  def is_picasa?
    link =~ /http:\/\/picasaweb\.google\.com/
  end
  
  # Return true if feed is a fotolog feed
  def is_fotolog?
    link =~ /\.fotolog\.com/
  end
  
  # Return true if feed is a google video feed
  def is_google_video?
    link =~ /http:\/\/video\.google\.com/
  end
  
  # Return true if feed is a jumpcut feed
  def is_jumpcut?
    link =~ /http:\/\/rss\.jumpcut\.com/
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
      Bug.raise_feed_bug(self, error, Bug::WARNING)
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
      Bug.raise_feed_bug(self, err)
    end
  end
  
  def Feed.remove_duplicates
    deleted_feeds = []
    @feeds = Feed.find(:all)
    @feeds.each do |feed|
      @duplicates = @feeds.select{|duplicate| duplicate.id != feed.id and duplicate.link == feed.link}
      @duplicates.each do |duplicate|
        Subscription.find(:all, :conditions => ["feed_id = ?", duplicate.id]).each {|sub| sub.update_attribute :feed_id, feed.id}
        Post.find(:all, :conditions => ["feed_id = ?", duplicate.id]).each {|post| post.update_attribute :feed_id, feed.id}
        @feeds.delete(duplicate)
        deleted_feeds << duplicate.link
        duplicate.destroy
      end
    end
    logger.debug "delete feed size: #{deleted_feeds.size}"
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

  def Feed.keep_unique_post
    Feed.find(:all).each {|feed|
      unless feed.nil?
        post = feed.latest_post
        unless post.nil?
          Post.find(:all, :conditions => ["id != ? AND feed_id = ?", post.id, feed.id]).each {|object| object.destroy}
        end
      end
    }
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
    Bug.destroy_all "feed_id = #{self.id}"
    Post.destroy_all "feed_id = #{self.id}"
    Subscription.destroy_all "feed_id = #{self.id}"
  end
end
