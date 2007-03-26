class Feevy < ActiveRecord::Base
  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end
  
  def Feevy.get_entries(user_id, tags)
    @entries = []
    @user = User.find(user_id, :include => [:subscriptions])
    
    if not @user.nil?
      
      if tags
        # Manage multitags
        tags = tags.gsub("+", ", ") if tags.include? '+'
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
            @entries << entry
          end
        end
      end

      # Sort by date to get latest posts first
      @entries = @entries.sort_by{|entry| entry[:date]}.reverse

      # Only get last displayed feeds depending on user choice
      if @user.opt_displayed_subscriptions != "all"
        @entries = @entries[1..@user.opt_displayed_subscriptions.to_i]
      end
    end
    return @entries
  end
end
