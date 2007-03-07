#--
# Copyright (c) 2005 Robert Aman
# Copyright (c) 2006 Juan Lupión
#
# Contributors: Jens Kraemer
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
#
#++

require 'autodiscovery'
require 'autodiscovery/helpers/generic_helper'

# This module provides helper methods for simplifying normal interactions with
# the Autodiscovery library.
module Autodiscovery
  module AutodiscoveryHelper
  
    @@default_local_path = File.expand_path('.')
  
    # Returns the default path to load local files from
    def self.default_local_path
      @@default_local_path
    end
  
    # Sets the default path to load local files from
    def self.default_local_path=(new_default_local_path)
      @@default_local_path = new_default_local_path
    end

  protected
    # Loads a feed within a block for more consistent syntax and control
    # over the Autodiscovery environment.
    def with_page(options={})
      
      Autodiscovery::GenericHelper.validate_options([ 
        :from_file,
        :from_url,
        :from_data],
        options.keys)
        
      if options[:from_file]
        file_path = File.expand_path(@@default_local_path + '/' +
          options[:from_file])
        if !File.exists?(file_path)
          file_path = File.expand_path(options[:from_file])
        end
        if !File.exists?(file_path)
          raise "No such file - #{file_path}"
        end
        page = Autodiscovery::Page.open("file://#{file_path}")
      elsif options[:from_url]
        page = Autodiscovery::Page.open(options[:from_url])
      elsif options[:from_data]
        page = Autodiscovery::Page.new
        page.page_data = options[:from_data]
      else
        raise "No data source specified"
      end
      yield page
      page = nil
    end
  end
end