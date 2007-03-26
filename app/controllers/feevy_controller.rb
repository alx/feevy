class FeevyController < ApplicationController
  
  def rss
    @user = User.find(params[:id])
    @entries = Feevy.get_entries(params[:id], params[:tags])
    
    # Title for the RSS feed
    @feed_title = "Feevy from #{@user.login}"
    # Get the absolute URL which produces the feed
    @feed_url = "http://www.feevy.com" + request.request_uri
    # Description of the feed as a whole
    @feed_description = "Feevy from #{@user.login}"
    @feed_description << " with tags: #{params[:tags].gsub("+", ", ")}" if params[:tags]
    # Set the content type to the standard one for RSS
    response.headers['Content-Type'] = 'application/rss+xml'
    # Render the feed using an RXML template
    render :action => 'rss', :layout => false
  end

  
  def show
    @entries = Feevy.get_entries(params[:id], params[:tags])
    
    # Get style parameter and set partial to load
    style = params[:style] || "dark"
    partial_style = "stylesheet"
    partial_badge = "badge"
    
    # Define layout
    if style == "light" || style == "liquid"
      partial_style << "_light"
      partial_badge << "_light"
    elsif style == "white"
      partial_style << "_white"
    end
    
    @style =  render_to_string(:partial => partial_style, :locals => { :id => params[:id]})
    @content = render_to_string(:partial => partial_badge, :locals => { :id => params[:id], :entradas => @entries} )
  end
end