#--
# Copyright (c) 2005 Robert Aman
# Copyright (c) 2006 Juan Lupion
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
require 'autodiscovery/vendor/htree'
require 'autodiscovery/helpers/xml_helper'

module Autodiscovery

  module FlickrHelper
    def self.scrape_flickr_avatar (html)
      html_document = HTree.parse_xml(html).to_rexml
      html_document.elements.each("/html/body//table[@id='flickr_badge_wrapper']/script") { |nodo|
        p "Nodo xpath: #{nodo}: src= #{nodo.attributes["src"]}"
        res = nodo.attributes["src"]
        resul=res.sub(/http:.*&user=/,"").sub(/&.*/,"")

        nsid = resul
        flickr_html = load_flickr_profile(nsid)

        
        html_document = HTree.parse_xml(flickr_html).to_rexml
        
        p html_document
        
        html_document.elements.each("/html/body//img[@class='logo']") { |nodo|
          return nodo.attributes["src"]
        }
      }
    end

    def self.load_flickr_profile (nsid)
      p "Nsid: #{nsid}"
      h = Net::HTTP.new("www.flickr.com", 80)
      
      resp, data = h.get("/people/#{nsid}", nil)
      puts "Code = #{resp.code}"
      puts "Message = #{resp.message}"
      
      return data
    end
  end
end