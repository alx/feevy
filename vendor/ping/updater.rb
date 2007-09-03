require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rfeedreader'

SERVER = "localhost:3000"
#SERVER = "www.feevy.com"

# Set your id for update service stats
ID = "testing"
# Set pinger hash to be verified on server side
HASH = ""

def update_feed(id, entry)
  res = Net::HTTP.post_form(URI.parse("http://#{SERVER}/ping/update_feed/#{id}"),
                                {:post_link => entry.link,
                                 :post_title => entry.title,
                                 :post_description => entry.description})
end

puts "Starting updates..."
while true
  begin
    doc = Hpricot(open("http://#{SERVER}/ping/list/#{ID}"), :xml => true)
    (doc/:feed).each do |feed|
      feed_id   = feed.at('id').innerHTML
      feed_rss  = feed.at('rss').innerHTML
      feed_post = feed.at('post').innerHTML
      puts "Feed #{feed_id}: #{feed_rss}"
      # Read feed rss
      begin
        entry = Rfeedreader.read_first(feed_rss).entries[0]
        # puts "Old: #{feed_post}"
        # puts "New: #{post_url}"
        # If url not the same, ping server
        if entry.link != feed_post then
          puts "updating #{feed_id}..."
          update_feed(feed_id, entry)
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
