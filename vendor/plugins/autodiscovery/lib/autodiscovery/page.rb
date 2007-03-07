#--
# Copyright (c) 2005 Robert Aman
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rexml/document'
require 'autodiscovery/helpers/retrieval_helper'
require 'autodiscovery/helpers/generic_helper'
require 'autodiscovery/helpers/xml_helper'
require 'autodiscovery/helpers/html_helper'

module Autodiscovery
  # The <tt>Autodiscovery::Page</tt> class represents a web page structure.
  class Page
    # Initialize the page object
    def initialize
      super
      @http_headers = nil
      @xml_document = nil
      @page_data = nil
      @page_data_type = :xml
      @root_node = nil
      @channel_node = nil
      @href = nil
      @id = nil
      @title = nil
      @description = nil
      @link = nil
      @last_retrieved = nil
      @time_to_live = nil
      @entries = nil
      @live = false
      @encoding = nil
      @options = nil
      reset
    end

    # Loads the page specified by the url.  Options supplied will 
    # override the default options.
    def Page.open(url, options={})
      Autodiscovery::GenericHelper.validate_options(
      Autodiscovery.configurations.keys, options.keys)

      # create the new feed
      page = Autodiscovery::Page.new

      page.configurations = Autodiscovery.configurations.merge(options)

      # clean up the url
      url = Autodiscovery::UriHelper.normalize_url(url)

      # load the new page
      page.href = url
      page.update! 
      Thread.pass
      return page
    end

    # clears any autodiscovered info
    def reset
      @autodiscovered_urls = {
        :atom => [],
        :rss => [],
        :rdf => [],
        :foaf => []
      }
      @autodiscovered_avatars = { 
        :foaf => nil,
        :flickr => nil,
        :blogspot => nil,
        :technorati => nil
      }  
    end
    
    
    # Returns the load options for this page.
    def configurations
      if @configurations.blank?
        @configurations = Autodiscovery.configurations.dup
      end
      return @configurations
    end

    # Sets the load options for this page.
    def configurations=(new_configurations)
      @configurations = new_configurations
    end

    # Loads the page from the remote url 
    def update!

      reset
      load_remote_page!
      
      link =Autodiscovery::HtmlHelper.extract_link_by_mime_type(
          self.page_data,
          "application/atom+xml")
      @autodiscovered_urls[:atom] << link unless link.blank?

      
      link = Autodiscovery::HtmlHelper.extract_link_by_mime_type(
          self.page_data,
          "application/rss+xml")
      @autodiscovered_urls[:rss] << link unless link.blank?


      link = Autodiscovery::HtmlHelper.extract_link_by_mime_type(
        self.page_data,
        "application/rdf+xml")
      @autodiscovered_urls[:rdf] << link unless link.blank?
      
      # only one FOAF link for now, please
      link = Autodiscovery::FoafHelper.extract_link_by_mime_type_and_title(
        self.page_data,
          "application/rdf+xml",
          "foaf"
      )
      @autodiscovered_urls[:foaf] = link unless link.blank?

      @autodiscovered_urls.values.map! { |type|
        if type.kind_of?(Array) 
          type.map! { |url|  
            Autodiscovery::UriHelper.resolve_relative_uri(
            url, [self.href] )
          }
        elsif type.kind_of?(String)
          type = Autodiscovery::UriHelper.resolve_relative_uri(
            type, [self.href])
        end 
      }
      
      rescue Exception
      begin
        raise
      end

    end

    
    def get_blogspot_avatar
      return nil unless Autodiscovery::configurations[:enable_blogspot_avatars] == true

      @autodiscovered_avatars[:blogspot] = 
        Autodiscovery::BlogspotHelper.scrape_blogspot_avatar(
          self.page_data)
    end
    
    def get_technorati_avatar
      return nil unless Autodiscovery::configurations[:enable_technorati_avatars] == true
      @autodiscovered_avatars[:technorati] = 
        Autodiscovery::TechnoratiHelper.get_technorati_avatar(
          self.href)
    end

    def get_flickr_avatar
      return nil unless Autodiscovery::configurations[:enable_flickr_avatars] == true
      @autodiscovered_avatars[:flickr] = 
        Autodiscovery::FlickrHelper.scrape_flickr_avatar(
          self.page_data)
    end

    def get_msn_avatar
      return nil unless Autodiscovery::configurations[:enable_msn_avatars] == true
      @autodiscovered_avatars[:msn] = 
        Autodiscovery::MsnHelper.scrape_msn_avatar(
          self.page_data)
    end

    def get_foaf_avatar
      return nil unless Autodiscovery::configurations[:enable_foaf_avatars] == true
      @autodiscovered_avatars[:foaf] = 
        Autodiscovery::FoafHelper.get_foaf_avatar(
          @autodiscovered_urls[:foaf])
    end

    def foaf_link
      @autodiscovered_urls[:foaf]
    end  
    
    def rss_feeds
      @autodiscovered_urls[:rss]
    end

    def atom_feeds
      @autodiscovered_urls[:atom]
    end

    def rdf_feeds
      @autodiscovered_urls[:rdf]
    end

  # def trace_feeds
  #     p self.href
  #     unless rss_feeds.blank? 
  #       rss_feeds.each do |feed|
  #         p feed
  #       end 
  #     end
  # 
  #     unless atom_feeds.blank?
  #       atom_feeds.each do |feed|
  #         p feed
  #       end 
  #     end
  # 
  #     unless rdf_feeds.blank?
  #       rdf_feeds.each do |feed|
  #         p feed
  #       end 
  #     end
  #   end

    # Attempts to load the feed from the remote location.  Requires the url
    # field to be set.  If an etag or the last_modified date has been set,
    # attempts to use them to prevent unnecessary reloading of identical
    # content.
    def load_remote_page!

      if (self.href =~ /^feed:/) == 0
        # Woah, Nelly, how'd that happen?  You should've already been
        # corrected.  So let's fix that url.  And please,
        # just use less crappy browsers instead of badly defined
        # pseudo-protocol hacks.
        self.href = Autodiscovery::UriHelper.normalize_url(self.href)
      end

      # Find out what method we're going to be using to obtain this feed.
      begin
        uri = URI.parse(self.href)
      rescue URI::InvalidURIError
        raise PageAccessError,
        "Cannot retrieve page using invalid URL: " + self.href.to_s
      end
      retrieval_method = "http"
      case uri.scheme
      when "http"
        retrieval_method = "http"
      when "ftp"
        retrieval_method = "ftp"
      when "file"
        retrieval_method = "file"
      when nil
        raise PageAccessError,
        "No protocol was specified in the url."
      else
        raise PageAccessError,
        "Cannot retrieve feed using unrecognized protocol: " + uri.scheme
      end

      # No need for http headers unless we're actually doing http
      if retrieval_method == "http"
        begin
          # FIXME estudir esto∫
          @http_response = (Autodiscovery::RetrievalHelper.http_get(
          self.href, :page_object => self) do |url, response|
            # Find out if we've already seen the url we've been
            # redirected to.
            follow_redirect = true
            follow_redirect
          end)

          case @http_response
          when Net::HTTPSuccess
            @page_data = self.http_response.body
            @http_headers = {}
            self.http_response.each_header do |key, value|
              self.http_headers[key.downcase] = value
            end
            self.last_retrieved = Time.now.gmtime
            @live = true
          when Net::HTTPNotModified
            @http_headers = {}
            self.http_response.each_header do |key, value|
              self.http_headers[key.downcase] = value
            end
            self.last_retrieved = Time.now.gmtime
            @live = false
          else
            @live = false
          end
        rescue Exception => error
          @live = false
          if self.page_data.nil?
            raise error
          end
        end
      elsif retrieval_method == "https"
        # Not supported... yet
      elsif retrieval_method == "ftp"
        # Not supported... yet
        # Technically, CDF feeds are supposed to be able to be accessed
        # directly from an ftp server.  This is silly, but we'll humor
        # Microsoft.
        #
        # Eventually.  If they're lucky.  And someone demands it.
      elsif retrieval_method == "file"
        # Now that we've gone to all that trouble to ensure the url begins
        # with 'file://', strip the 'file://' off the front of the url.
        file_name = self.href.gsub(/^file:\/\//, "")
        if RUBY_PLATFORM =~ /mswin/
          file_name = file_name[1..-1] if file_name[0..0] == "/"
        end
        begin
          open(file_name) do |file|
            @http_response = nil
            @http_headers = {}
            @page_data = file.read
            @page_data_type = :xml
            self.last_retrieved = Time.now.gmtime
          end
        rescue
          # In this case, pulling from the cache is probably not going
          # to help at all, and the use should probably be immediately
          # appraised of the problem.  Raise the exception.
          raise
        end
      end
    end

    # Returns the relevant information from an http request.
    def http_response
      return @http_response
    end

    # Returns a hash of the http headers from the response.
    def http_headers
      if @http_headers.blank?
        @http_headers = {}
      end
      return @http_headers
    end

    # Returns the encoding that the feed was parsed with
    def encoding
      if @encoding.nil?
        unless self.http_headers.blank?
          @encoding = "utf-8"
        else
          @encoding = self.encoding_from_page_data
        end
      end
      return @encoding
    end

    # Returns the encoding of feed calculated only from the xml data.
    # I.e., the encoding we would come up with if we ignore RFC 3023.
    def encoding_from_page_data
      if @encoding_from_page_data.nil?
        raw_data = self.page_data
        encoding_from_xml_instruct = 
        raw_data.scan(
        /^<\?xml [^>]*encoding="([\w]*)"[^>]*\?>/
        ).flatten.first
        unless encoding_from_xml_instruct.blank?
          encoding_from_xml_instruct.downcase!
        end
        if encoding_from_xml_instruct.blank?
          doc = REXML::Document.new(raw_data)
          encoding_from_xml_instruct = doc.encoding.downcase
          if encoding_from_xml_instruct == "utf-8"
            # REXML has a tendency to report utf-8 overzealously, take with
            # grain of salt
            encoding_from_xml_instruct = nil
          end
        else
          @encoding_from_page_data = encoding_from_xml_instruct
        end
        if encoding_from_xml_instruct.blank?
          sniff_table = {
            "Lo\247\224" => "ebcdic-cp-us",
            "<?xm" => "utf-8"
          }
          sniff = self.page_data[0..3]
          if sniff_table[sniff] != nil
            @encoding_from_page_data = sniff_table[sniff].downcase
          end
        else
          @encoding_from_page_data = encoding_from_xml_instruct
        end
        if @encoding_from_page_data.blank?
          # Safest assumption
          @encoding_from_page_data = "utf-8"
        end
      end
      return @encoding_from_page_data
    end

    # Returns the feed's raw data.
    def page_data
      return @page_data
    end

    # Sets the feed's data.
    def page_data=(new_page_data)
      for var in self.instance_variables
        self.instance_variable_set(var, nil)
      end
      @http_headers = {}
      @page_data = new_page_data
    end


    # Returns the feed url.
    def href
      return @href
    end

    # Sets the feed url and prepares the cache_object if necessary.
    def href=(new_href)
      @href = Autodiscovery::UriHelper.normalize_url(new_href)
    end




    # Returns the url to the icon file for this feed.
    # def icon
    #   if @icon.nil?
    #     icon_node = Autodiscovery::XmlHelper.try_xpaths(self.channel_node, [
    #       "link[@rel='icon']",
    #       "link[@rel='shortcut icon']",
    #       "link[@type='image/x-icon']",
    #       "icon",
    #       "logo[@style='icon']",
    #       "LOGO[@STYLE='ICON']"
    #     ])
    #     unless icon_node.nil?
    #       @icon = Autodiscovery::XmlHelper.try_xpaths(icon_node, [
    #         "@atom10:href",
    #         "@atom03:href",
    #         "@atom:href",
    #         "@href",
    #         "text()"
    #       ], :select_result_value => true)
    #       begin
    #         if !(@icon =~ /^file:/) &&
    #             !Autodiscovery::UriHelper.is_uri?(@icon)
    #           channel_base_uri = nil
    #           unless self.channel_node.nil?
    #             channel_base_uri = self.channel_node.base_uri
    #           end
    #           @icon = Autodiscovery::UriHelper.resolve_relative_uri(
    #             @icon, [channel_base_uri, self.base_uri])
    #         end
    #       rescue
    #       end
    #       @icon = nil unless Autodiscovery::UriHelper.is_uri?(@icon)
    #       @icon = nil if @icon.blank?
    #     end
    #   end
    #   return @icon
    # end

    # Returns the favicon url for this feed.
    # This method first tries to use the url from the link field instead of
    # the feed url, in order to avoid grabbing the favicon for services like
    # feedburner.
    # def favicon
    #   if @favicon.nil?
    #     if !self.link.blank?
    #       begin
    #         link_uri = URI.parse(
    #           Autodiscovery::UriHelper.normalize_url(self.link))
    #         if link_uri.scheme == "http"
    #           @favicon =
    #             "http://" + link_uri.host + "/favicon.ico"
    #         end
    #       rescue
    #         @favicon = nil
    #       end
    #       if @favicon.nil? && !self.href.blank?
    #         begin
    #           feed_uri = URI.parse(
    #             Autodiscovery::UriHelper.normalize_url(self.href))
    #           if feed_uri.scheme == "http"
    #             @favicon =
    #               "http://" + feed_uri.host + "/favicon.ico"
    #           end
    #         rescue
    #           @favicon = nil
    #         end
    #       end
    #     else
    #       @favicon = nil
    #     end
    #   end
    #   return @favicon
    # end


    # The time that the feed was last requested from the remote server.  Nil
    # if it has never been pulled, or if it was created from scratch.
    def last_retrieved
      return @last_retrieved
    end

    # Sets the time that the feed was last updated.
    def last_retrieved=(new_last_retrieved)
      @last_retrieved = new_last_retrieved
    end

    # passes missing methods to the cache_object
    def method_missing(msg, *params)
      if self.cache_object.nil?
        raise NoMethodError, "Invalid method #{msg.to_s}"
      end
    end

    def Page.method_missing(msg, *params)
      if self.cache_object.nil?
        raise NoMethodError, "Invalid method #{msg.to_s}"
      end
    end

    # Returns a simple representation of the page object's state.
    def inspect
      return "#<Autodiscovery::Page:0x#{self.object_id.to_s(16)} URL:#{self.href}>"
    end

  end
end
