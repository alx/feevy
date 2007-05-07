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

  validates_uniqueness_of :href
  validates_presence_of :link, :title, :href
  
  before_destroy :destroy_relationship
    
  
  # before_save :generate_hashed_gravatar
  # before_update :generate_hashed_gravatar
  # 
  # def generate_hashed_gravatar
  #   return if gravatar_email.blank?
  #   
  #   self.gravatar_md5 = Digest::MD5.hexdigest(self.gravatar_email)
  #   self.latest_post_time = 0
  #   self.latest_post_description = "Esta bitácora no ha sido analizada aún"
  #   self.latest_post_title = ""
  #   self.latest_post_link = ""
  # end
  
  # Discover avatar.txt file to update avatar
  def Feed.update_avatars
    Feed.find(:all).each { |feed| 
      unless feed.bogus == true
        logger.info "+++ Refresh avatar: #{feed.href}"
        feed.discover_avatar_txt
      else
        logger.info "--- Not refreshing avatar: #{feed.href}"
      end
    }
  end

  def Feed.create_from_blog(url)
    # clean up the url
    begin
    url = FeedTools::UriHelper.normalize_url(url)
    rescue => err
      logger.debug "err: #{err}"
    end
    if url.nil?
      return nil
    else
      # find existing feed
      feed = Feed.find :first, :conditions => ["href LIKE ?", url]
      
      if feed.nil?
        begin
          # Create new Feed
          feed = Feed.create(:href => url, :avatar_id => 1)
          logger.debug "Feed ID: #{feed.id}"
          
          # Update feed header
          feed.update_feed_header
          
          # Find duplicate
          @duplicates = Feed.find :all, :conditions => ["link LIKE ?", feed.link]
          if @duplicates.size > 1
            feed.destroy
            feed = @duplicates[0] 
          end
          
          # Refresh feed to update content and avatar
          feed.refresh
          
          # Discover avatar
          feed.discover_avatar_txt
        rescue => error
          logger.error "Error while creating a feed from blog: #{error.message}"
          return error
        end
      end
      
      return feed
    end
  end
  
  def Feed.is_rss?(url)
    url =~ /\.xml$/ or
    url =~ /\.rdf$/ or
    url =~ /rss$/ or
    url =~ /rss2$/ or
    url =~ /atom$/ or
    url =~ /^http:\/\/feeds\.feedburner\.com/ or
    url =~ /\/?rss=1$/ or
    url =~ /rss\.php/ or
    url =~ /rss2\.php/ or
    url =~ /\/rss\.html$/ or
    url =~ /\?q=node\/feed$/ or
    url =~ /\/rss\// or
    url =~ /\/feed\// or
    url =~ /\/feeds\//
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
  
  def Feed.create_from_rss(url)
    # Open rss document
    doc = Hpricot(open(url))
    # Create feed with href, title and link
    feed = Feed.new :href => doc.search("link").text, :title => doc.search("title").text, :link => url
    feed.save
  end
  
  def has_error
    return Bug.feed_error(self).nil? ? false : true
  end
  
  alias bogus has_error
  
  def has_warnings
    return Bug.feed_warnings(self).empty? ? false : true
  end

  def update_feed_header(test=false)
    begin
      # Get first item
      doc = Hpricot(open(self.href))
      # Get charset
      charset = doc.to_s.scan(/charset=['"]?([^'"]*)['" ]/)
      charset = charset[0] if charset.is_a? Array
      charset = charset.to_s.downcase
    
      title = link = ""
    
      title = doc.search("//title:first").text
    
      if self.href =~ /http:\/\/video\.google\.com/
        rss_link = self.href << "&num=1&so=1&start=0&output=rss"
      else
        rss_link  = doc.search("//link[@type='application/rss+xml']").to_s.scan(/href=['"]?([^'"]*)['" ]/)
        rss_link = rss_link[0].to_s if rss_link.is_a? Array
      
        atom_link = doc.search("//link[@type='application/atom+xml']").to_s.scan(/href=['"]?([^'"]*)['"]/)
        atom_link = atom_link[0].to_s if atom_link.is_a? Array
      end
    
      # Set link as atom link if rss is still blank
      link = rss_link
      link = atom_link if link.blank?
      logger.debug "link: #{link}"
    
      # Bogus feed when link is not found
      if link.blank?
        bug_message = "RSS/Atom link not found on this website"
        Bug.raise_feed_bug(self, bug_message) unless self.bogus == true
        raise bug_message
      else
        # complete bogus link with website href
        if link !~ /^http:\/\// 
          link = self.href << link.gsub(/^\//,"")
        end
      
        self.update_attributes :title => Feed.format_title(title, charset),
                               :link => link
      end
    rescue => error
      Bug.raise_feed_bug(self, error) unless self.bogus == true
    end 
    return self
  end
  
  def Feed.format_title(title, charset='utf-8')
    clean(convertEncoding(title, charset)).downcase
  end
  
  def update_content_hpricot(forced=false)
    unless bogus == true
      begin
        # Get first item
        Timeout::timeout(30) do
          doc = Hpricot(open(link), :xml => true)
          item = doc.search("item:first|entry:first")
          # Get charset
          charset = doc.to_s.scan(/encoding=['"]?([^'"]*)['" ]/)
          charset = charset[0] if charset.is_a? Array
          charset = charset.to_s.downcase
          
          unless item.nil?
            # get item url
            post_url = read_link(item)
            # built Post from first item if different url
            if (not post_url.nil?) and (forced or latest_post.nil? or post_url != latest_post.url)
              
              # Get and format post title
              title = Post.format_title(item.search("title").text, charset)
              logger.debug "title: #{title}"
              
              # Test if picasa feed
              if is_picasa?
                description = Post.picasa_description(item, post_url)
              # Test if picasa feed
              elsif is_flickr?
                description = Post.flickr_description(item, post_url)
              # Test if google video feed
              elsif is_google_video?
                description = Post.google_video_description(item, post_url)
              # Test if jumpcut feed
              elsif is_jumpcut?
                description = Post.jumpcut_description(item, post_url)
              # Else normal feed
              else
                description = Post.format_description(item.search("description|summary|content").text, charset)
              end
              logger.debug "description: #{description}"
              # Delete existing post if forced update
              if forced == true
                post = Post.find(:first, :conditions => ["url LIKE ? AND feed_id = ?", post_url, self.id])
                post.destroy unless post.nil?
              end
              # Save new post
              posts << Post.new(:url => post_url, 
                                :title => title, 
                                :description => description, 
                                :feed_id => id)
            end
          end
        end
      rescue Timeout::Error
        Bug.raise_feed_bug(self, "timeout", Bug::WARNING)
      rescue => err
        Bug.raise_feed_bug(self, err) unless bogus == true
      end
    end
  end
  
  alias refresh update_content_hpricot
  
  # Return true if feed is a flickr feed
  def is_flickr?
    link =~ /http:\/\/api\.flickr\.com/
  end
  
  # Return true if feed is a flickr feed
  def is_picasa?
    link =~ /http:\/\/picasaweb\.google\.com/
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
      avatar_link = open(self.href.gsub(/[^\/]$/, "/") << "avatar.txt")
      
      unless avatar_link.nil?
        avatar_url = avatar_link.readline
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
            unless avatar.nil?
              self.update_attributes :avatar_id => avatar.id,
                                     :avatar_locked => true
            end
          end
        end
      end
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
        deleted_feeds << duplicate.link
        duplicate.destroy
      end
    end
  end
  
  def Feed.move_blogspot_to_rss
    @feeds = Feed.find(:all)
    @feeds.each do |feed|
      if feed.href =~ /(blogspot)|(blogger)/ and feed.link !~ /rss/
        begin
          puts "Moving #{feed.href} from atom: #{feed.link}"
          feed.update_feed_header
          feed.update_feed_content
          puts "to rss: #{feed.link}"
        rescue
        end
      end
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
  
  private
  def destroy_relationship
    Bug.destroy_all "feed_id = #{self.id}"
    Post.destroy_all "feed_id = #{self.id}"
    Subscription.destroy_all "feed_id = #{self.id}"
  end
end
