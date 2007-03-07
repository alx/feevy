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

require 'autodiscovery'
require 'autodiscovery/helpers/xml_helper'
require 'rexml/document'

module Autodiscovery
  # Methods for pulling remote data
  module HtmlHelper
    # Escapes all html entities
    def self.escape_entities(html)
      return nil if html.nil?
      escaped_html = CGI.escapeHTML(html)
      escaped_html.gsub!(/'/, "&apos;")
      escaped_html.gsub!(/"/, "&quot;")
      return escaped_html
    end

    # Unescapes all html entities
    def self.unescape_entities(html)
      return nil if html.nil?
      unescaped_html = html
      unescaped_html.gsub!(/&#x26;/, "&amp;")
      unescaped_html.gsub!(/&#38;/, "&amp;")
      unescaped_html = unescaped_html.gsub(/&#x\d+;/) do |hex|
        "&#" + hex[3..-2].to_i(16).to_s + ";"
      end
      unescaped_html = CGI.unescapeHTML(unescaped_html)
      unescaped_html.gsub!(/&apos;/, "'")
      unescaped_html.gsub!(/&quot;/, "\"")
      return unescaped_html
    end

    # Removes all html tags from the html formatted text, but leaves
    # escaped entities alone.
    def self.strip_html_tags(html)
      return nil if html.nil?
      stripped_html = html
      stripped_html.gsub!(/<\/?[^>]+>/, "")
      return stripped_html
    end
    
    # Removes all html tags from the html formatted text and removes
    # escaped entities.
    def self.convert_html_to_plain_text(html)
      return nil if html.nil?
      stripped_html = html
      stripped_html = Autodiscovery::HtmlHelper.strip_html_tags(stripped_html)
      stripped_html = Autodiscovery::HtmlHelper.unescape_entities(stripped_html)
      stripped_html.gsub!(/&#8216;/, "'")
      stripped_html.gsub!(/&#8217;/, "'")
      stripped_html.gsub!(/&#8220;/, "\"")
      stripped_html.gsub!(/&#8221;/, "\"")
      return stripped_html  
    end
    

    # Indents a text selection by a specified number of spaces.
    def self.indent(text, spaces)
      lines = text.split("\n")
      buffer = ""
      for line in lines
        line = " " * spaces + line
        buffer << line << "\n"
      end
      return buffer
    end

    # Unindents a text selection by a specified number of spaces.
    def self.unindent(text, spaces)
      lines = text.split("\n")
      buffer = ""
      for line in lines
        for index in 0...spaces
          if line[0...1] == " "
            line = line[1..-1]
          else
            break
          end
        end
        buffer << line << "\n"
      end
      return buffer
    end

    # Removes all dangerous html tags from the html formatted text.
    # If mode is set to :escape, dangerous and unknown elements will
    # be escaped.  If mode is set to :strip, dangerous and unknown
    # elements and all children will be removed entirely.
    # Dangerous or unknown attributes are always removed.
    def self.sanitize_html(html, mode=:strip)
      return nil if html.nil?

      # Lists borrowed from Mark Pilgrim's feedparser
      acceptable_elements = ['a', 'abbr', 'acronym', 'address', 'area', 'b',
                             'big', 'blockquote', 'br', 'button', 'caption', 'center', 'cite',
                             'code', 'col', 'colgroup', 'dd', 'del', 'dfn', 'dir', 'div', 'dl',
                             'dt', 'em', 'fieldset', 'font', 'form', 'h1', 'h2', 'h3', 'h4',
                             'h5', 'h6', 'hr', 'i', 'img', 'input', 'ins', 'kbd', 'label', 'legend',
                             'li', 'map', 'menu', 'ol', 'optgroup', 'option', 'p', 'pre', 'q', 's',
                             'samp', 'select', 'small', 'span', 'strike', 'strong', 'sub', 'sup',
                             'table', 'tbody', 'td', 'textarea', 'tfoot', 'th', 'thead', 'tr', 'tt',
                             'u', 'ul', 'var']

      acceptable_attributes = ['abbr', 'accept', 'accept-charset', 'accesskey',
                               'action', 'align', 'alt', 'axis', 'border', 'cellpadding',
                               'cellspacing', 'char', 'charoff', 'charset', 'checked', 'cite', 'class',
                               'clear', 'cols', 'colspan', 'color', 'compact', 'coords', 'datetime',
                               'dir', 'disabled', 'enctype', 'for', 'frame', 'headers', 'height',
                               'href', 'hreflang', 'hspace', 'id', 'ismap', 'label', 'lang',
                               'longdesc', 'maxlength', 'media', 'meta', 'method', 'multiple', 'name',
                               'nohref', 'noshade', 'nowrap', 'prompt', 'readonly', 'rel', 'rev',
                               'rows', 'rowspan', 'rules', 'scope', 'selected', 'shape', 'size',
                               'span', 'src', 'start', 'summary', 'tabindex', 'target', 'title',
                               'type', 'usemap', 'valign', 'value', 'vspace', 'width']

      # Replace with appropriate named entities
      html.gsub!(/&#x26;/, "&amp;")
      html.gsub!(/&#38;/, "&amp;")
      html.gsub!(/&lt;!'/, "&amp;lt;!'")

      # Hackity hack.  But it works, and it seems plenty fast enough.
      html_doc = HTree.parse_xml("<root>" + html + "</root>").to_rexml

      sanitize_node = lambda do |html_node|
        if html_node.respond_to? :children
          for child in html_node.children
            if child.kind_of? REXML::Element
              unless acceptable_elements.include? child.name.downcase
                if mode == :strip
                  html_node.delete_element(child)
                else
                  new_child = REXML::Text.new(CGI.escapeHTML(child.to_s))
                  html_node.insert_after(child, new_child)
                  html_node.delete_element(child)
                end
              end
              child.attributes.each_attribute do |attribute|
                if !(attribute.value =~ /^xmlns(:.+)?$/)
                  unless acceptable_attributes.include?(
                                                        attribute.value.downcase)
                    child.delete_attribute(attribute.value)
                  end
                end
              end
            end
            sanitize_node.call(child)
          end
        end
        html_node
      end
      sanitize_node.call(html_doc.root)
      html = html_doc.root.inner_xml
      return html
    end

    # Returns true if the type string provided indicates that something is
    # xml or xhtml content.
    def self.xml_type?(type)
      if [
          "xml",
          "xhtml",
          "application/xhtml+xml"
         ].include?(type)
        return true
      elsif type != nil && type[-3..-1] == "xml"
        return true
      else
        return false
      end
    end

    # Returns true if the type string provided indicates that something is
    # html or xhtml content.
    def self.text_type?(type)
      return [
              "text",
              "text/plain"
             ].include?(type)
    end
    
    # Returns true if the type string provided indicates that something is
    # html or xhtml content.
    def self.html_type?(type)
      return [
              "html",
              "xhtml",
              "text/html",
              "application/xhtml+xml"
             ].include?(type)
    end

    # Returns true if the type string provided indicates that something is
    # only html (not xhtml) content.
    def self.only_html_type?(type)
      return [
              "html",
              "text/html"
             ].include?(type)
    end
    
    # Resolves all relative uris in a block of html.
    def self.resolve_relative_uris(html, base_uri_sources=[])
      relative_uri_attributes = [
                                 ["a", "href"],
                                 ["applet", "codebase"],
                                 ["area", "href"],
                                 ["blockquote", "cite"],
                                 ["body", "background"],
                                 ["del", "cite"],
                                 ["form", "action"],
                                 ["frame", "longdesc"],
                                 ["frame", "src"],
                                 ["iframe", "longdesc"],
                                 ["iframe", "src"],
                                 ["head", "profile"],
                                 ["img", "longdesc"],
                                 ["img", "src"],
                                 ["img", "usemap"],
                                 ["input", "src"],
                                 ["input", "usemap"],
                                 ["ins", "cite"],
                                 ["link", "href"],
                                 ["object", "classid"],
                                 ["object", "codebase"],
                                 ["object", "data"],
                                 ["object", "usemap"],
                                 ["q", "cite"],
                                 ["script", "src"]
                                ]
      html_doc = HTree.parse_xml("<root>" + html + "</root>").to_rexml
      
      resolve_node = lambda do |html_node|
        if html_node.kind_of? REXML::Element
          for element_attribute_pair in relative_uri_attributes
            if html_node.name.downcase == element_attribute_pair[0]
              attribute = html_node.attribute(element_attribute_pair[1])
              if attribute != nil
                href = attribute.value
                href = Autodiscovery::UriHelper.resolve_relative_uri(
                                                                     href, [html_node.base_uri] | base_uri_sources)
                html_node.attribute(
                                    element_attribute_pair[1]).instance_variable_set(
                                                                                     "@value", href)
              end
            end
          end
        end
        if html_node.respond_to? :children
          for child in html_node.children
            resolve_node.call(child)
          end
        end
        html_node
      end
      resolve_node.call(html_doc.root)
      html = html_doc.root.inner_xml
      return html
    end
    
    # Returns a string containing normalized xhtml from within a REXML node.
    def self.extract_xhtml(rexml_node)
      rexml_node_dup = rexml_node.deep_clone
      namespace_hash = FEED_TOOLS_NAMESPACES.dup
      normalize_namespaced_xhtml = lambda do |node, node_dup|
        if node.kind_of? REXML::Element
          node_namespace = node.namespace
          if node_namespace != namespace_hash['atom10'] &&
              node_namespace != namespace_hash['atom03']
            # Massive hack, relies on REXML not changing
            for index in 0...node.attributes.values.size
              attribute = node.attributes.values[index]
              attribute_dup = node_dup.attributes.values[index]
              if attribute.namespace == namespace_hash['xhtml']
                attribute_dup.instance_variable_set(
                                                    "@expanded_name", attribute.name)
              end
              if node_namespace == namespace_hash['xhtml']
                if attribute.name == 'xmlns'
                  node_dup.attributes.delete('xmlns')
                end
              end
            end
            if node_namespace == namespace_hash['xhtml']
              node_dup.instance_variable_set("@expanded_name", node.name)
            end
            if !node_namespace.blank? && node.prefix.blank?
              if node_namespace != namespace_hash['xhtml']
                prefix = nil
                for known_prefix in namespace_hash.keys
                  if namespace_hash[known_prefix] == node_namespace
                    prefix = known_prefix
                  end
                end
                if prefix.nil?
                  prefix = "unknown" +
                    Digest::SHA1.new(node_namespace).to_s[0..4]
                  namespace_hash[prefix] = node_namespace
                end
                node_dup.instance_variable_set("@expanded_name",
                                               "#{prefix}:#{node.name}")
                node_dup.instance_variable_set("@prefix",
                                               prefix)
                node_dup.add_namespace(prefix, node_namespace)
              end
            end
          end
        end
        for index in 0...node.children.size
          child = node.children[index]
          if child.kind_of? REXML::Element
            child_dup = node_dup.children[index]
            normalize_namespaced_xhtml.call(child, child_dup)
          end
        end
      end
      normalize_namespaced_xhtml.call(rexml_node, rexml_node_dup)
      buffer = ""
      rexml_node_dup.each_child do |child|
        if child.kind_of? REXML::Comment
          buffer << "<!--" + child.to_s + "-->"
        else
          buffer << child.to_s
        end
      end
      return buffer.strip
    end
    
    # Given a REXML node, returns its content, normalized as HTML.
    def self.process_text_construct(content_node, feed_type, feed_version,
                                    base_uri_sources=[])
      if content_node.nil?
        return nil
      end
      
      content = nil
      root_node_name = nil
      type = Autodiscovery::XmlHelper.try_xpaths(content_node, "@type",
                                                 :select_result_value => true)
      mode = Autodiscovery::XmlHelper.try_xpaths(content_node, "@mode",
                                                 :select_result_value => true)
      encoding = Autodiscovery::XmlHelper.try_xpaths(content_node, "@encoding",
                                                     :select_result_value => true)

      if type.nil?
        atom_namespaces = [
                           FEED_TOOLS_NAMESPACES['atom10'],
                           FEED_TOOLS_NAMESPACES['atom03']
                          ]
        if ((atom_namespaces.include?(content_node.namespace) ||
             atom_namespaces.include?(content_node.root.namespace)) ||
            feed_type == "atom")
          type = "text"
        end
      end
      
      # Note that we're checking for misuse of type, mode and encoding here
      if content_node.cdatas.size > 0
        content = content_node.cdatas.first.to_s.strip
      elsif type == "base64" || mode == "base64" ||
          encoding == "base64"
        content = Base64.decode64(content_node.inner_xml.strip)
      elsif type == "xhtml" || mode == "xhtml" ||
          type == "xml" || mode == "xml" ||
          type == "application/xhtml+xml" ||
          content_node.namespace == FEED_TOOLS_NAMESPACES['xhtml']
        content = Autodiscovery::HtmlHelper.extract_xhtml(content_node)
      elsif type == "escaped" || mode == "escaped" ||
          type == "html" || mode == "html" ||
          type == "text/html" || mode == "text/html"
        content = Autodiscovery::HtmlHelper.unescape_entities(
                                                              content_node.inner_xml.strip)
      elsif type == "text" || mode == "text" ||
          type == "text/plain" || mode == "text/plain"
        content = Autodiscovery::HtmlHelper.unescape_entities(
                                                              content_node.inner_xml.strip)
      else
        content = content_node.inner_xml.strip
        repair_entities = true
      end
      if type == "text" || mode == "text" ||
          type == "text/plain" || mode == "text/plain"
        content = Autodiscovery::HtmlHelper.escape_entities(content)
      end        
      unless content.nil?
        if Autodiscovery.configurations[:sanitization_enabled]
          content = Autodiscovery::HtmlHelper.sanitize_html(content, :strip)
        end
        content = Autodiscovery::HtmlHelper.resolve_relative_uris(content,
                                                                  [content_node.base_uri] | base_uri_sources)
        if repair_entities
          content = Autodiscovery::HtmlHelper.unescape_entities(content)
        end
      end
      if Autodiscovery.configurations[:tab_spaces] != nil
        spaces = Autodiscovery.configurations[:tab_spaces].to_i
        content.gsub!("\t", " " * spaces) unless content.blank?
      end
      content.strip unless content.blank?
      content = nil if content.blank?
      return content
    end

    # Strips semantically empty div wrapper elements
    def self.strip_wrapper_element(xhtml)
      return nil if xhtml.nil?
      return xhtml if xhtml.blank?
      begin
        doc = REXML::Document.new(xhtml.to_s.strip)
        if doc.children.size == 1
          child = doc.children[0]
          if child.kind_of?(REXML::Element) && child.name.downcase == "div"
            return child.inner_xml.strip
          end
        end
        return xhtml.to_s.strip
      rescue Exception
        return xhtml.to_s.strip
      end
    end
    
    # Given a block of html, locates feed links with a given mime type.
    def self.extract_link_by_mime_type(html, mime_type)
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
              link.attributes['rel'].to_s.strip.downcase == "alternate"
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
    
  

   
    
    
  end
end
