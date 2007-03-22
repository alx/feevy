class FeevyController < ApplicationController
  def show
    @entradas = []
    @user = User.find(params[:id], :include => [:subscriptions])
    if not @user.nil?
      
      if params[:tags]
        tags = params[:tags].gsub("+", ", ")
        subscriptions = @user.subscriptions.find_tagged_with(tags)
      else
        subscriptions = @user.subscriptions
      end
      subscriptions.each do |subscription|
        feed = subscription.feed
        if (not feed.nil?) and (not feed.bogus == true) then
          post = feed.latest_post
          unless post.nil?
            entry = Hash.new
            entry[:name]      = feed.title.nil? ? "" : feed.title
            entry[:blog_url]  = feed.href.nil? ? "" : feed.href
            entry[:title]     = post.title.nil? ? "" : post.title
            entry[:date]      = post.created_at
            entry[:texto]     = post.description.nil?  ? "" : post.description
            entry[:post_url]  = post.url
            entry[:img]       = feed.avatar_locked == 1 ? feed.avatar.url : subscription.avatar.url 
            @entradas << entry
          end
        end
      end

      # Sort by date to get latest posts first
      @entradas = @entradas.sort_by{|entrada| entrada[:date]}.reverse

      # Only get last displayed feeds depending on user choice
      if @user.opt_displayed_subscriptions != "all"
        @entradas = @entradas[1..@user.opt_displayed_subscriptions.to_i]
      end

      # Get style parameter and set partial to load
      style = params[:style] || "dark"
      partial_style = "stylesheet"
      partial_badge = "badge"

      # If user ask for liquid partial
      if style == "light" || style == "liquid"
        partial_style << "_light"
        partial_badge << "_light"
      elsif style == "white"
        partial_style << "_white"
      end

      @style =  render_to_string(:partial => partial_style, :locals => { :id => @user.id})
      @content = render_to_string(:partial => partial_badge, :locals => { :id => @user.id, :entradas => @entradas} )

    end
  end
end