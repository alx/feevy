class BugController < ApplicationController
  
  require_auth 'admin'
  
  def index
    @bugs = Feed.find :all, :conditions => "status = 0"
  end
  
  ####
  # RJS actions
  ####
  
  def bogus_test    
    @bug = Bug.find(params[:id])
    @status = "bogus_ok"
    @status = "bogus_error" if @bug.feed.test == 1
  end
  
  def bogus_resolve
    @bug = bug.find(params[:id])
    @bug.resolve
  end
  
end
