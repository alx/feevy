# Technorati-Ruby - Technorati[http://technorati.com/] bindings for Ruby[http://ruby-lang.org/].
# by Paul Duncan <mailto:pabs@pablotron.org>
#
# For the latest version of this software, Please see the 
# Technorati-Ruby page at 
# http://pablotron.org/software/technorati-ruby/.
#
# Copyright (C) 2004 Paul Duncan.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies of the Software, its documentation and
# marketing & publicity materials, and acknowledgment shall be given
# in the documentation, materials and software packages that this
# Software was used.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#--
# :title: Technorati-Ruby API Documentation
#++
#

require 'parsedate'
require 'net/http'
require 'rexml/document'

class String
  #
  # Escape XML-special characters in string.
  #
  def xml_escape
    str = gsub(/&/, '&amp;')
    str = str.gsub(/</, '&lt;')
    str = str.gsub(/>/, '&gt;')
    str = str.gsub(/"/, '&quot;')
    str
  end

  #
  # XML escape elements, including spaces, ?, and +
  #
  def uri_escape
    str = xml_escape.gsub(/\+/, '&43;')
    str = str.gsub(/\s/, '+')
    str = str.gsub(/\?/, '&63;')
  end
end

class Technorati
  VERSION = '0.1.0'

  TYPE_PROCS = {
    :str  => proc { |str| str },
    :int  => proc { |str| str.to_i },
    :time => proc { |str| Time::mktime(*ParseDate::parsedate(str)) },
    :flt  => proc { |str| str.to_f },
  }

  QUERY_SCHEMAS = {
    'cosmos'  => {
      'weblog/name'         => :str,
      'weblog/url'          => :str,
      'weblog/rssurl'       => :str,
      'weblog/atomurl'      => :str,
      'weblog/inboundblogs' => :int,
      'weblog/inboundlinks' => :int,
      'weblog/lastupdate'   => :time,
      'nearestpermalink'    => :str,
      'exerpt'              => :str,
      'linkcreated'         => :time,
      'linkurl'             => :str,

      # these are all <result>-specific
      'weblog/rank'         => :int,
      'rankingstart'        => :int,
      'url'                 => :str,
    },

    'search'  => {
      'query'               => :str,
      'querycount'          => :int,
      'inboundblogs'        => :int,
      'querytime'           => :flt, # check this
      'rankingstart'        => :int,

      'weblog/name'         => :str,
      'weblog/url'          => :str,
      'weblog/rssurl'       => :str,
      'weblog/atomurl'      => :str,
      'weblog/inboundblogs' => :int,
      'weblog/inboundlinks' => :int,
      'weblog/lastupdate'   => :time,
      'title'               => :str,
      'exerpt'              => :str,
      'created'             => :time,
    },

    'getinfo' => {
      'username'            => :str,
      'firstname'           => :str,
      'lastname'            => :str,
      'thumbnailpicture'    => :str,
      
      'weblog/name'         => :str,
      'weblog/url'          => :str,
      'weblog/rssurl'       => :str,
      'weblog/atomurl'      => :str,
      'weblog/inboundblogs' => :int,
      'weblog/inboundlinks' => :int,
      'weblog/lastupdate'   => :time,
      'rank'                => :int,
      'lang'                => :str,
      'lat'                 => :str,
      'lon'                 => :str,
      'foafurl'             => :str,
    },

    'outbound'  => {
      'url'                 => :str,
      'weblog/name'         => :str,
      'weblog/url'          => :str,
      'weblog/rssurl'       => :str,
      'weblog/atomurl'      => :str,
      'weblog/inboundblogs' => :int,
      'weblog/inboundlinks' => :int,
      'weblog/lastupdate'   => :time,
      'weblog/rank'         => :int,
      'inboundblogs'        => :int,
      'inboundlinks'        => :int,
      'rankingstart'        => :int,
    },

    'bloginfo'  => {
      'url'                 => :str,
      'weblog/name'         => :str,
      'weblog/url'          => :str,
      'weblog/rssurl'       => :str,
      'weblog/atomurl'      => :str,
      'weblog/inboundblogs' => :int,
      'weblog/inboundlinks' => :int,
      'weblog/lastupdate'   => :time,
      'weblog/rank'         => :int,
      'weblog/author/thumbnailpicture' => :str,
      'inboundblogs'        => :int,
      'inboundlinks'        => :int,
    },
  }

  #
  # Connect to Technorati with key +key+
  #
  # Note: if the key is invalid, Technorati-Ruby will not raise an
  # exception until you make an actual call.  You can get a key from
  # http://technorati.com/developers/.
  #
  # Example: 
  #   # read key from $HOME/.technorati_key and use it to connect
  #   key = IO::readlines(File::join(ENV['HOME'], '.technorati_key')).join.strip
  #   t = Technorati.new(key)
  #
  def initialize(key)
    @key = key
    @headers = {
      'User-Agent'  => "Technorati-Ruby/#{Technorati::VERSION} Ruby/#{RUBY_VERSION}"
    }
  end

  #
  # Low-level HTTP GET.
  #
  # This method is private.
  #
  def http_get(url)
    # set HTTP version to 1.2
    Net::HTTP::version_1_2

    # connect to technorati
    http = Net::HTTP.new('api.technorati.com', 80)
    http.start

    # $stderr.puts "DEBUG URL: #{url}"

    # get URL, check for error
    resp = http.get(url, @headers);
    raise "HTTP #{resp.code}: #{resp.message}" unless resp.code =~ /2\d{2}/

    # close HTTP connection, return response
    http.finish
    resp.body
  end

  #
  # Get URL from Technorati, and optionally parse result and return as
  # an array of hashes as well.
  #
  # This method is private.
  #
  def get(schema, url)
    p schema, url 
    content = http_get(url)
    p content
    doc = REXML::Document.new(content)

    # if there was an error, raise an exception
    doc.root.elements.each('//error') do |e|
      raise "Technorati Error: #{e.text}"
    end

    # grab toplevel result info
    result_elem = doc.root.elements['//result']
    ret = QUERY_SCHEMAS[schema].keys.inject({}) do |elem_vals, key|
      if val = result_elem.elements[key]
        # out_key = key.gsub(/\//, '_')
        out_val = TYPE_PROCS[QUERY_SCHEMAS[schema][key]].call(val.text)
        elem_vals[key] = out_val
      end
      elem_vals
    end

    # grab each result item and toss it in the return array
    ret['items'] = []
    doc.root.elements.each('//item') do |e|
      # elements to grab from return XML
      ret['items'] << QUERY_SCHEMAS[schema].keys.inject({}) do |elem_vals, key| 
        if val = e.elements[key]
          # out_key = key.gsub(/\//, '_')
          out_val = TYPE_PROCS[QUERY_SCHEMAS[schema][key]].call(val.text)
          elem_vals[key] = out_val
        end
        elem_vals
      end
    end

    # return results
    ret
  end

  # don't touch these :)
  private :get, :http_get

  # 
  # Returns the results of a Technorati[http://technorati.com/]
  # CosmosQuery[http://developers.technorati.com/wiki/CosmosQuery].  A
  # Technorati[http://technorati.com/]
  # CosmosQuery[http://developers.technorati.com/wiki/CosmosQuery]
  # lets you see what blogs are linking to a given URL.
  #
  # Arguments:
  # * +url+ (required): URL you are searching for. The 'http://' prefix is
  #   optional.
  # * +limit+: Set this to a number larger than 0 and smaller or equal to
  #   100 and it will return +limit+ number of links for a query. By
  #   default this value is 20.
  # * +type+: Set this to 'link' and you'll get the freshest links to your
  #   target URL. Set it to 'weblog' and you'll get a reverse blogroll -
  #   the last set of blogs that linked to the target URL.
  # * +start+: Set this to a number larger than 0 and you'll get the
  #   +start+ + +limit+ freshest items (links or blogs), e.g. set it to
  #   +limit+ + 1, and you'll get the second page of rankings.
  # * +current+: By default, cosmos returns the links that are currently
  #   on the source's index page. If you set current to no, you will have
  #   all links to the given URL.
  #
  # Returns a hash containing information about the query URL and a 
  # list of blogs.
  #
  # Valid Return Keys:
  # * 'weblog/name': Name of blog.
  # * 'weblog/url':  URL of blog.
  # * 'weblog/rssurl': RSS syndication URL of blog.
  # * 'weblog/atomurl': Atom syndication URL of blog.
  # * 'weblog/inboundblogs': Number of inbound blogs.
  # * 'weblog/inboundlinks': Number of inbound links.
  # * 'weblog/lastupdate': Date of last update.
  # * 'nearestpermalink': Nearest permanent link.
  # * 'exerpt': Exerpt from page matching search result.
  # * 'linkcreated': Date link was created.
  # * 'linkurl': Link URL.
  # * 'weblog/rank': Cosmos Rank.
  # * rankingstart:
  # * 'url': URL.
  # * 'items': an array of hashes containing blogs
  #
  # Raises an exception on error.
  #
  # Example:
  #   # print out a list of the first 35 sites linking to slashdot.org
  #   puts t.cosmos('slashdot.org', 35)['items'].map do |item|
  #     item['weblog/name']
  #   end
  #
  def cosmos(url, limit = nil, type = nil, start = nil, current = nil)
    args = ["key=#@key", "url=#{url.uri_escape}", (type ? "type=#{type}" : nil), (limit ? "limit=#{limit}" : nil), (start ? "start=#{start}" : nil), (current ? "current=#{current}" : nil)]
    get('cosmos', '/cosmos?' << args.compact.join('&'))
  end

  #
  # Returns the results of a Technorati[http://technorati.com/] SearchQuery[http://developers.technorati.com/wiki/SearchQuery].  A 
  # Technorati[http://technorati.com/] SearchQuery[http://developers.technorati.com/wiki/SearchQuery] lets you see what blogs contain a given search string.
  # 
  # Arguments: 
  # * +words+ (required): an Array of words or a whitespace-separated String
  # * +start+: Set this to a number larger than 0 and you'll get the
  #   +start+ + 20 freshest items (links or blogs), e.g. set it to 20+1,
  #   and you'll get the second page of rankings 21-40.
  #
  # Returns a hash containing information about the query and a 
  # list of blogs.
  #
  # Valid Return Keys:
  # * 'query': Query string.  
  # * 'querycount': Number of matches.
  # * 'inboundblogs': Number of inbound blogs.
  # * 'querytime': Duration of query (in seconds).
  # * 'rankingstart': Value of start parameter.
  # * 'weblog/name': Name of blog containing match.
  # * 'weblog/url': URL of blog containing match.
  # * 'weblog/rssurl': RSS URL of blog containing match.
  # * 'weblog/atomurl': Atom URL of blog containing match.
  # * 'weblog/inboundblogs': Number of inbound blogs of blog containing
  #   match.
  # * 'weblog/inboundlinks': Number of inbound links of blog containing
  #   match.
  # * 'weblog/lastupdate': Date blog was last updated
  # * 'title': Title of matching entry.
  # * 'exerpt': Exerpt of matching entry with relevant text.
  # * 'created': Date matching entry was created.
  # * 'items': Array of hashes containing matching entries.
  #
  # Raises an exception on error.
  #
  # Example:
  #   # print out a list of the first 20 entries that match the
  #   # phrase 'cooking'
  #   puts t.search('cooking')['items'] do |item|
  #     ["Blog: #{item['weblog/url']}", 
  #      "Entry Title: #{item['title']}",
  #      "Entry Date: #{item['created']}",
  #      "Entry Exerpt: #{item['exerpt']}",
  #      '']
  #   end.flatten
  #
  def search(words, start = nil)
    words = [words] unless words.is_a? Array
    args = ["key=#@key", "query=#{words.join(' ').uri_escape}", (start ? "start=#{start}" : nil)]
    get('search', '/search?' << args.compact.join('&'))
  end

  #
  # Returns the results of a Technorati[http:/technorati.com/] GetInfoQuery[http://developers.technorati.com/wiki/GetInfoQuery].  A Technorati[http:/technorati.com/] GetInfoQuery[http://developers.technorati.com/wiki/GetInfoQuery] tells you things that Technorati knows about a user.
  # In the simplest case you can use Technorati#info to find out information
  # that a blogger wants to make known about himself, along with some
  # information that Technorati has calculated and verified about that
  # person. The returned info is broken up into two sections: The first
  # part describes some information that the user wants to allow people
  # to know about him- or herself. The second part of the document is a
  # listing of the weblogs that the user has successfully claimed and
  # the information that Technorati knows about these weblogs.
  #
  # Arguments:
  # *  +user+ (required): Username
  #
  # Returns a hash containing information about the user and a 
  # list of blogs associated with that user.
  #
  # Valid Return Keys:
  # * 'username': User name of user.
  # * 'firstname': First name of user.
  # * 'lastname': Last name of user.
  # * 'thumbnailpicture': URL to thumbnail picture.
  # * 'weblog/name': Name of blog containing match.
  # * 'weblog/url: URL of blog containing match.
  # * 'weblog/rssurl': RSS URL of blog containing match.
  # * 'weblog/atomurl': Atom URL of blog containing match.
  # * 'weblog/inboundblogs': Number of inbound blogs of blog containing
  #   match.
  # * 'weblog/inboundlinks': Number of inbound links of blog containing
  #   match.
  # * 'weblog/lastupdate': Date blog was last updated.
  # * 'rank': Cosmos ranking.
  # * 'lang': Blog language as integer.
  # * 'lat': Geographical information.
  # * 'lon': Geographical information.
  # * 'foafurl': FOAF[http://foaf.org/] URL.
  # * 'items': an Array of Hashes with each matched user's blog.
  #
  # Raises an exception on error.
  #
  # Example:
  #   # print out a list of blog URLs associated with 'giblet'
  #   puts t.info('giblet')['items'] map { |blog| blog['weblog/url'] }
  #
  def info(user)
    args = ["key=#@key", "username=#{user.uri_escape}"]
    get('getinfo', '/getinfo?' << args.compact.join('&'))
  end

  #
  # Returns the results of a Technorati[http:/technorati.com/] OutboundQuery[http://developers.technorati.com/wiki/OutboundQuery].  A Technorati[http:/technorati.com/] OutboundQuery[http://developers.technorati.com/wiki/OutboundQuery] query</a> lets you see what blogs are linked to on a given
  # blog, including their associated info.
  #
  # Arguments:
  # * +url+ (required): URL to search for.
  #
  # Returns a hash containing information about the query URL and a 
  # list of blogs.
  #
  # Valid Return Keys:
  # * 'url': Blog URL.
  # * 'weblog/name': Name of blog.
  # * 'weblog/url: URL of blog.
  # * 'weblog/rssurl': RSS URL of blog.
  # * 'weblog/atomurl': Atom URL of blog.
  # * 'weblog/inboundblogs': Number of inbound blogs of blog.
  # * 'weblog/inboundlinks': Number of inbound links of blog.
  # * 'weblog/lastupdate': Date blog was last updated.
  # * 'weblog/rank': Blog cosmos rank.
  # * 'inboundblogs': Inbound blogs.
  # * 'inboundlinks': Inbound links. 
  # * 'rankingstart': Start parameter value.
  # * 'items': an Array of Hashes containing blogs linking to the given
  #   blog.
  #
  # Raises an exception on error.
  #
  # Example:
  #   # print out a list of blogs linking to 'engadget.com'
  #   puts t.outbound('engadget.com')['items'].map { |blog| blog['weblog/name'] } 
  #
  def outbound(url, start = nil)
    args = ["key=#@key", "url=#{url.uri_escape}", (start ? "start=#{start}" : nil)]
    get('outbound', '/outbound?' << args.compact.join('&'))
  end

  #
  # Returns the results of a Technorati[http:/technorati.com/] BlogInfoQuery[http://developers.technorati.com/wiki/BlogInfoQuery].  A  Technorati[http:/technorati.com/] BlogInfoQuery[http://developers.technorati.com/wiki/BlogInfoQuery]
  # provides info on what blog, if any, is associated
  # with a given URL. It also returns additional info such as cosmos
  # stats, RSS feed Give it any URL and it'll tell you what blog, if
  # any, that URL came from, and all the info it has on that blog, like
  # cosmos stats and RSS feed.
  #
  # Arguments:
  # * +url+ (required): URL to search for.
  #
  # Returns a hash containing information about the query URL.
  #
  # Valid Return Keys:
  # * 'url': Blog URL.
  # * 'weblog/name': Name of blog.
  # * 'weblog/url: URL of blog.
  # * 'weblog/rssurl': RSS URL of blog.
  # * 'weblog/atomurl': Atom URL of blog.
  # * 'weblog/inboundblogs': Number of inbound blogs of blog.
  # * 'weblog/inboundlinks': Number of inbound links of blog.
  # * 'weblog/lastupdate': Date blog was last updated.
  # * 'weblog/rank': Blog cosmos rank.
  # * 'inboundblogs': Inbound blogs.
  # * 'inboundlinks': Inbound links. 
  #
  # Raises an exception on error.
  #
  # Example:
  #   # print out the Name, URL, and RSS URL for atrios.blogspot.com
  #   result = t.bloginfo('atrios.blogspot.com')
  #   blog_keys = { 'Name' => 'name', 'URL' =>'url', 'RSS' => 'rssurl' }
  #   puts blog_keys.map { |ary| "#{ary[0]}: #{result['weblog/' + ary[1]]}" }
  #   
  def bloginfo(url, start = nil)
    args = ["key=#@key", "url=#{url.uri_escape}"]
    ret = get('bloginfo', '/bloginfo?' << args.compact.join('&'))
    ret.delete('items')
    ret
  end

end
