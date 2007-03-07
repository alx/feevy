#--
# Copyright (c) 2005 Robert Aman
# 
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

require 'autodiscovery'
require 'uri'
  
module Autodiscovery
  # Generic url processing methods needed in numerous places throughout
  # Autodiscovery
  module UriHelper
    
    # Returns true if the idn module can be used.
    def self.idn_enabled?
      # This is an override variable to keep idn from being used even if it
      # is available.
      if Autodiscovery.configurations[:idn_enabled] == false
        return false
      end
      if @idn_enabled.nil? || @idn_enabled == false
        @idn_enabled = false
        begin
          require 'idn'
          if IDN::Idna.toASCII('http://www.詹姆斯.com/') ==
            "http://www.xn--8ws00zhy3a.com/"
            @idn_enabled = true
          else
            @idn_enabled = false
          end
        rescue LoadError
          # Tidy not installed, disable features that rely on tidy.
          @idn_enabled = false
        end
      end
      return @idn_enabled
    end
    
    # Attempts to ensures that the passed url is valid and sane.  Accepts very,
    # very ugly urls and makes every effort to figure out what it was supposed
    # to be.  Also translates from the feed: and rss: pseudo-protocols to the
    # http: protocol.
    def self.normalize_url(url)
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
            if Autodiscovery::UriHelper.idn_enabled?
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
          page_uri = URI.parse(normalized_url)
          if page_uri.scheme == nil
            page_uri.scheme = "http"
          end
          if page_uri.path.blank?
            page_uri.path = "/"
          end
          if (page_uri.path =~ /^[\/]+/) == 0
            page_uri.path.gsub!(/^[\/]+/, "/")
          end
          while (page_uri.path =~ /^\/\.\./)
            page_uri.path.gsub!(/^\/\.\./, "")
          end
          if page_uri.path.blank?
            page_uri.path = "/"
          end
          page_uri.host.downcase!
          normalized_url = page_uri.to_s
        rescue URI::InvalidURIError
        end
      end

      # We can't do a proper set of escaping, so this will
      # have to do.
      normalized_url.gsub!(/%20/, " ")
      normalized_url.gsub!(/ /, "%20")

      return normalized_url
    end

    # Resolves a relative uri
    def self.resolve_relative_uri(relative_uri, base_uri_sources=[])
      return relative_uri if base_uri_sources.blank?
      return nil if relative_uri.nil?
      begin
        base_uri = URI.parse(
          Autodiscovery::XmlHelper.select_not_blank(base_uri_sources))
        resolved_uri = base_uri
        if relative_uri.to_s != ''
          resolved_uri = base_uri + relative_uri.to_s
        end
        return Autodiscovery::UriHelper.normalize_url(resolved_uri.to_s)
      rescue
        return relative_uri
      end
    end
   end
end