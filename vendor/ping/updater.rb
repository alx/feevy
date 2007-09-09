require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rfeedreader'

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
    puts "Checking: #{@rss}"
    begin
      @entry = Rfeedreader.read_first(@rss).entries[0]
      @updated = true if !@entry.nil? and (@post_link.nil? or @entry.link != @post_link)
    rescue => err
      puts "Error while checking feed updates: #{err}"
    end
  end
end

class Updater
  
  attr_accessor :server, :id, :password, :ready
  
  def initialize
    @ready = false
    config = YAML::load(File.open(File.join(File.dirname(__FILE__), 
'config.yml')))

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
      puts "Error with updater login info, please verify your config.yml"
    end
  end
  
  def update_cycle
    request_feed_list.each do |feed| 
      update(feed) if feed.updated? 
    end
  end

  def update(feed)
    puts "Update!"
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
      puts "#{feed_list.size} feeds loaded"
    rescue => err
      puts "Error while requesting feed list: #{err}"
      puts "Waiting a minute..."
      sleep(60)
    end
    return feed_list
  end
end

updater = Updater.new
if updater.ready
  puts "Starting updates..."
  while true
    updater.update_cycle
    puts "Pinging cycle finished, restarting it"
    puts "===="
  end
end
