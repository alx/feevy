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
require 'uri'

module Autodiscovery

  # Generic methods needed in numerous places throughout Autodiscovery
  module FoafHelper

    # ditto for FOAF links
    def self.extract_link_by_mime_type_and_title (html, mime_type, title)
      require 'autodiscovery/vendor/htree'
      require 'autodiscovery/helpers/xml_helper'

      # This is technically very, very wrong.  But it saves oodles of
      # clock cycles, and probably works 99.999% of the time.
      html_document = HTree.parse_xml(        
      html.gsub(/<body.*?>(.|\n)*<\/body>/, "<body>-</body>")).to_rexml

      html_node = nil
      head_node = nil
      link_nodes = []

      for node in html_document.children
        next unless node.kind_of?(REXML::Element)
        if node.name.downcase == "html" &&
          node.children.size > 0
          html_node = node
          break
        end
      end
      return nil if html_node.nil?
      for node in html_node.children
        next unless node.kind_of?(REXML::Element)
        if node.name.downcase == "head"
          head_node = node
          break
        end
        if node.name.downcase == "link"
          link_nodes << node
        end
      end
      return nil if html_node.nil? && link_nodes.empty?
      if !head_node.nil?
        link_nodes = []
        for node in head_node.children
          next unless node.kind_of?(REXML::Element)
          if node.name.downcase == "link"
            link_nodes << node
          end
        end
      end
      find_link_nodes = lambda do |links|
        for link in links
          next unless link.kind_of?(REXML::Element)

          if link.attributes['type'].to_s.strip.downcase ==
            mime_type.downcase &&
            link.attributes['title'].to_s.strip.downcase == title.downcase
            href = link.attributes['href']
            return href unless href.blank?
          end
        end
        for link in links
          next unless link.kind_of?(REXML::Element)
          find_link_nodes.call(link.children)
        end
      end
      find_link_nodes.call(link_nodes)
      return nil
    end

    def self.get_foaf_avatar(url)
      foaf_xml = load_foaf_profile(url)
      foaf_document = HTree.parse_xml(foaf_xml).to_rexml
      
      p foaf_document
      
      # only for TheCocktail by now
      foaf_document.elements.each("/rdf:RDF/foaf:Person//foaf:Image") { |nodo|
        return nodo.attributes["rdf:about"]
      }
      
      # only for Vox
      foaf_document.elements.each("/rdf:RDF/Person[@rdf:nodeID='me']//img") { |nodo|
        return nodo.attributes["rdf:resource"]
      }
      
      # for Liveournal/Typepad (not all blogs)
      foaf_document.elements.each("/rdf:RDF/foaf:Person//foaf:img") { |nodo|
        # p "Nodo: #{nodo}"
        return nodo.attributes["rdf:resource"]
      }
      
      
      return nil
    end
    
    def self.load_foaf_profile(url)
      p "URI para get_foaf_avatar #{url}"
      
      uri=URI.parse(url)
      
      h=Net::HTTP.new(uri.host, (uri.port or 80))
      resp, data = h.get(uri.path)
      puts "Code = #{resp.code}"
      puts "Message = #{resp.message}"
      return data
    end
  end
end