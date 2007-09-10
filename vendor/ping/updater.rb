require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rfeedreader'
require 'logger'

class Feed
  attr_accessor :id, :rss, :post_link, :updated, :entry
  
  def initialize(feed)
    @id         = feed.at('id').innerHTML
    @rss        = feed.at('rss').innerHTML
    @post_link  = feed.at('post').innerHTML unless feed.at('post').nil?
    @updated    = false
    @entry      = nil
  end
  
  def updated?
    feed = Rfeedreader.read_first(@rss)
    raise "Unreadable feed" if feed.nil? or feed.entries[0].nil?
    @entry = feed.entries[0]
    @updated = true if @post_link.nil? or @entry.link != @post_link
  end
end

class Updater
  
  attr_accessor :server, :id, :password, :ready, :logger
  
  def initialize
    @ready = false
    config = YAML::load(File.open(File.join(File.dirname(__FILE__), 'config.yml')))

    @logger = Logger.new(File.join(File.dirname(__FILE__), 'updater.log'), 10, 1024000)

    # Set server url
    @server = config['server']
    # Set your id for update service stats
    @id = config['username']
    # Set pinger hash to be verified on server side
    @password = config['password']

    begin
      open("http://#{@server}/ping/verify/#{@id}-#{@password}")
      @ready = true
    rescue
      @logger.error "Error with updater login info, please verify your config.yml"
    end
  end
  
  def update_cycle
    request_feed_list.each do |feed|
      @logger.info "Checking #{feed.rss}"
      begin
        update(feed) if feed.updated?
      rescue => err
        @logger.error "Error while checking #{feed.rss}: " << err 
      end 
    end
  end

  def update(feed)
    @logger.info "Update!"
    res = Net::HTTP.post_form(URI.parse("http://#{@server}/ping/update_feed/#{feed.id}"),
                              {:pinger_password => @password,
                               :post_link => feed.entry.link,
                               :post_title => feed.entry.title,
                               :post_description => feed.entry.description})
  end

  def request_feed_list
    feed_list = []
    begin
      doc = Hpricot(open("http://#{@server}/ping/list/#{@id}"), :xml => true)
      (doc/:feed).each do |feed_info|
        feed_list << Feed.new(feed_info)
      end
      @logger.info "#{feed_list.size} feeds loaded"
    rescue => err
      @logger.error "Error while requesting feed list: #{err}"
      @logger.warning "Waiting a minute..."
      sleep(60)
    end
    return feed_list
  end
end

updater = Updater.new
if updater.ready
  while true
    updater.update_cycle
  end
end
