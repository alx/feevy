#--
# Copyright (c) 2005 Robert Aman
#
# Permission is# hereby granted, free of charge, to any person obtaining
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

if Object.const_defined?(:AUTODISCOVERY_NAMESPACES)
  warn("Autodiscovery may have been loaded improperly.  This may be caused " +
    "by the presence of the RUBYOPT environment variable or by using " +
    "load instead of require.  This can also be caused by missing " +
    "the Iconv library, which is common on Windows.")
end

AUTODISCOVERY_ENV = ENV['AUTODISCOVERY_ENV'] ||
                    ENV['RAILS_ENV'] ||
                    'development' # :nodoc:

AUTODISCOVERY_NAMESPACES = {
  "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "rss09" => "http://my.netscape.com/rdf/simple/0.9/",
  "rss10" => "http://purl.org/rss/1.0/",
  "rss11" => "http://purl.org/net/rss1.1#",
  "rss20" => "http://backend.userland.com/rss2",
  "xml" => "http://www.w3.org/XML/1998/namespace"
}

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + "/autodiscovery/vendor")

begin
  require 'autodiscovery/version'


# FIXME 
#   begin
#     require 'iconv'
#   rescue Object
#     warn("The Iconv library does not appear to be installed properly.  " +
# |      "Autodiscovery cannot function properly without it.")
#     raise
#   end

  require 'rubygems'

  require_gem('builder', '>= 1.2.4')
  if !defined?(ActiveSupport)    
    require_gem('activesupport', '>= 1.1.1')  
  end

  require 'net/http'
  require 'rexml/document'
  require 'uri'
  require 'time'
  require 'cgi'
  require 'pp'
  require 'yaml'
  require 'base64'
  
  require 'autodiscovery/vendor/technorati'
  require 'active_support/core_ext'
  
  require 'autodiscovery/vendor/htree'
  require 'autodiscovery/monkey_patch'
  require 'autodiscovery/page'
  require 'autodiscovery/helpers/html_helper'
  require 'autodiscovery/helpers/xml_helper'
  require 'autodiscovery/helpers/uri_helper'
  require 'autodiscovery/helpers/flickr_helper'
  require 'autodiscovery/helpers/technorati_helper'
  require 'autodiscovery/helpers/blogspot_helper'  
  require 'autodiscovery/helpers/foaf_helper'
  require 'autodiscovery/helpers/msn_helper'
    
rescue LoadError
  # ActiveSupport will very likely mess this up.  So drop a warn so that the
  # programmer can figure it out if things get wierd and unpredictable.
  warn("Unexpected LoadError, it is likely that you don't have one of the " +
    "libraries installed correctly.")
  raise
end

#= autodiscovery.rb

module Autodiscovery
  @configurations = {}
  
  def Autodiscovery.load_configurations
    if @configurations.blank?
      config_hash = {}
      @configurations = {
        :proxy_address => nil, # ok 
        :proxy_port => nil,    # ok
        :proxy_user => nil,    # ok
        :proxy_password => nil, # ok 
        :user_agent => 
          "Autodiscovery/#{Autodiscovery::AUTODISCOVERY_VERSION::STRING} " + 
          "+http://www.sobrerailes.com/projects/autodiscovery/", # ok
        :idn_enabled => true,
        :sanitization_enabled => true,
        :sanitize_with_nofollow => true,
        :always_strip_wrapper_elements => true,
        :timestamp_estimation_enabled => true,
        :url_normalization_enabled => true,
        :entry_sorting_property => "time",
        :strip_comment_count => false,
        :tab_spaces => 2,
        :max_ttl => 3.days.to_s,
        :output_encoding => "utf-8",

        # API keys for web services
        :technorati_api_key => "",  
        :flickr_apy_key => "",

        # Some config options
        :enable_flickr_avatars => true,
        :enable_technorati_avatars => true,
        :enable_blogspot_avatars => true,
        :enable_foaf_avatars => true,
        :enable_msn_avatars => true
      }.merge(config_hash)
    end
    return @configurations
  end
  
  # Resets configuration to a clean load
  def Autodiscovery.reset_configurations
    @configurations = nil
    Autodiscovery.load_configurations
  end
  
  # Returns the configuration hash for Autodiscovery
  def Autodiscovery.configurations
    if @configurations.blank?
      Autodiscovery.load_configurations()
    end
    return @configurations
  end
  
  # Sets the configuration hash for Autodiscovery
  def Autodiscovery.configurations=(new_configurations)
    @configurations = new_configurations
  end
  
  # Error raised when a page cannot be retrieved    
  class PageAccessError < StandardError
  end
    
end

