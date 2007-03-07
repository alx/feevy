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

module Autodiscovery

  # Generic methods needed in numerous places throughout Autodiscovery
  module MsnHelper

    def self.scrape_msn_avatar (html)
      require 'autodiscovery/vendor/htree'
      require 'autodiscovery/helpers/xml_helper'

      html_document = HTree.parse_xml(html).to_rexml

      html_document.elements.each("//div[@id='ProfileContactControl']") { |nodo|
        p "Nodo XML: #{nodo}"
        return nodo.attributes["contactparams:photopreauthurl"]
      }
      return nil
    end
  end
end