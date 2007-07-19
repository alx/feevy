# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'auth_system'
class ApplicationController < ActionController::Base
    include AuthSystem
    helper :auth
    before_filter :app_config, :ident
    after_filter :set_charset
    service :notification

    # Used to be able to leave out the action
    def process(request, response)
      catch(:abort) do
        super(request, response)
      end
      response
    end

    def this_auth
      @app
    end
    helper_method :this_auth
    
    def set_charset
        content_type = headers["Content-Type"] || "text/html" 
        if /^text\//.match(content_type)
          headers["Content-Type"] = "#{content_type}; charset=utf-8" 
        end
    end
end