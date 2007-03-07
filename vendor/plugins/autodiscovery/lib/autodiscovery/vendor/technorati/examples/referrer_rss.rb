#!/usr/bin/env ruby

#######################################################################
# referrer_rss.rb - build a RSS feed of site referrers                #
# by Paul Duncan <pabs@pablotron.org>                                 #
#######################################################################

# load technorati bindings
require 'technorati'

# get URL from command-line, load key
URL = ARGV.shift || 'pablotron.org'
KEY = IO::readlines(File::join(ENV['HOME'], '.technorati_key')).join.strip

# connect to technorati
t = Technorati.new(KEY)

# run cosmos query for URL
results = t.cosmos(URL)

# iterate over results and build RSS output of data
puts <<END_HEADER
<?xml version='1.0' encoding='iso-8859-1'?>
<rss version='0.92'>
  <channel>
    <title>Technorati: Sites Linking to #{URL}</title>
    <link>http://technorati.com/</link>
    <description>
      A list of sites linking to #{URL} according to 
      &lt;a href='http://technorati.com/'&gt;Technorati&lt;/a&gt;.
    </description>
    
END_HEADER

# iterate over each returned site and print out a link
results['items'].each do |item|
  puts "
  <item>
    <title>#{item['weblog/name']}</title>
    <link>#{item['weblog/url']}</link>
    <date>#{item['linkcreated']}</date>
    <description>
      This site links to #{URL}. 
      #{item['exerpt'] ? 'Exerpt:' << item['exerpt'] : ''}
    </description>
  </item>"
end

# close off RSS feed
puts "</channel>\n</rss>\n"
