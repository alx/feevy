require 'rubygems'
require 'hpricot'
require 'open-uri'

#SERVER = "localhost:3000"
SERVER = "www.feevy.com"

puts "Starting updates..."
while true
  begin
    doc = Hpricot(open("http://#{SERVER}/ping/list"), :xml => true)
    (doc/:feed).each do |feed|
      feed_id   = feed.at('id').innerHTML
      feed_rss  = feed.at('rss').innerHTML
      feed_post = feed.at('post').innerHTML
      puts "Feed #{feed_id}: #{feed_rss}"
      # Read feed rss
      begin
        dist = Hpricot(open(feed.at('rss').innerHTML), :xml => true)
        item = dist.search("item:first|entry:first")
        # Get first post url
        link = item.search("link:first")
        unless link.nil?
          post_url = link.text
          post_url = link.to_s.scan(/href=['"]?([^'"]*)['" ]/).to_s if (post_url.nil? or post_url.empty?)
        end
        puts "Old: #{feed_post}"
        puts "New: #{post_url}"
        # If url not the same, ping server
        if post_url != feed_post then
          puts "pinging #{feed_id}..."
          open("http://#{SERVER}/ping/update/#{feed_id}")
        end
      rescue Timeout::Error
        puts "Timeout on this feed"
      rescue => err
        puts "Error while reading this feed: #{err}"
      end
    end  
  rescue Timeout::Error
    puts "Timeout on this cycle"
  rescue => err
    puts "Error on this cycle: #{err} - Waiting a minute"
    sleep(60)
  end
  puts "Pinging cycle finished, restarting it"
  puts "===="
end