require 'rubygems'
require 'hpricot'
require 'open-uri'


puts "Starting updates..."
while true
  doc = Hpricot(open("http://www.feevy.com/ping/list"), :xml => true)
  (doc/:feed).each do |feed|
    feed_id   = feed.at('id').innerHTML
    feed_rss  = feed.at('rss').innerHTML
    feed_post = feed.at('post').innerHTML
    # Read feed rss
    dist = Hpricot(open(feed.at('rss').innerHTML), :xml => true)
    item = dist.search("item:first|entry:first")
    # Get first post url
    link = item.search("link:first")
    unless link.nil?
      post_url = link.text
      post_url = link.to_s.scan(/href=['"]?([^'"]*)['" ]/).to_s if (post_url.nil? or post_url.empty?)
    end
    # If url not the same, ping server
    if post_url != feed_post then
      puts "pinging #{feed_id}..."
      open("http://www.feevy.com/ping/update/#{feed_id}")
    end
  end
  puts "Pinging cycle finished, restarting it"
  puts "===="
end