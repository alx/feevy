class ManageController < ApplicationController

  def index
    require_auth
    case @user.registration_stage 
    when 0
      select_blogs
      render :action => 'select_blogs'
    when 1
      @subscriptions = @user.just_added_subscriptions
      # Do not select avatar if nothing to select
      if not @subscriptions.detect{ |sub| sub.feed.avatar_locked == 1 }.nil?
        @user.subscriptions_added
        @user.update_attribute :registration_stage, 2
        flash[:message] = "Feeds has been added to your Feevy list."
        redirect_to :action => 'index'
      else
        render :action => 'select_avatars'
      end
    else
      show_code
      render :action => 'show_code'
    end
  end
  
  def select_blogs
    require_auth
    if request.post?
      @user.update_attributes(:registration_stage => 1)
      params[:blogs].each do |blog|
        # Do not process this blog if it's empty
        unless blog.empty?
          begin
            # Create or find a feed using specified blog url
            feed = Feed.create_from_blog(blog)
            raise "Empty feed" if feed.nil?
            flash[:message] = "Feed has been added to your Feevy list."
            if @user.add_subscription(feed).nil?
              flash[:message] = "You've already got this feed in your Feevy."
              @user.update_attribute :registration_stage, 2
            end
          rescue => err
            flash[:warning] = "A problem occured with a feed: #{err.message}"
          end
        end
      end
      redirect_to :action => 'index'
    end
  end
  
  def select_blogs_with_opml
    require_auth
    if request.post?
      @user.update_attributes(:registration_stage => 1)
      unless params[:opml_file].nil?
        
        tempfile = Tempfile.new('tmp')
        tempfile.write params[:opml_file].read
        tempfile.flush
        
        if tempfile.nil? or !Feed.is_opml?(tempfile)
          flash[:warning] = "Error while reading OPML file"
        else
          begin
            feeds = Feed.create_from_opml(tempfile)
            subscription_size = @user.add_subscriptions(feeds)
            flash[:message] = "#{subscription_size} feeds has been added to your Feevy list."
            if subscription_size == 0
              flash[:message] = "You've already got all your OPML feeds in your Feevy."
              @user.update_attribute :registration_stage, 2
            end
          rescue => err
            flash[:warning] = "A problem occured with a feed: #{err.message}"
          end
        end
      end
      redirect_to :action => 'index'
    end
  end
  
  def select_avatars
    require_auth
  end
  
  def avatar_selected
    require_auth
    @user.subscriptions_added
    @user.update_attributes(:registration_stage => 2)
    redirect_to :action => 'index'
  end
  
  def show_code
    require_auth
    @subscriptions = @user.subscriptions
  end

  ###
  # RJS actions
  ###

  def show_blog
    check_user
    @headers["Content-Type"] = "text/javascript"
    @subscription = Subscription.find(params[:id])
  end

  def select_avatar
    check_user
    @update_avatar = params[:update_avatar]
    @subscription = Subscription.find(params[:id])
    @subscription.update_attribute :avatar_id, params[:avatar_id]
  end

  def change_avatar
    check_user
    @headers["Content-Type"] = "text/javascript"
    @subscription = Subscription.find params[:id]
  end

  def upload_avatar
    check_user
    @subscription = Subscription.find params[:subscription][:id]
    filename = @params[:subscription][:picture].original_filename

    if @params[:subscription][:picture] and not @params[:subscription][:picture] == "" and
      not @params[:subscription][:picture].original_filename.empty?
      if not @params[:subscription][:picture].content_type.chomp =~ /^image/
        flash[:warning] = "Your picture isn't an image !" 
        return false
      else

        tempfile = Tempfile.new('tmp')
        tempfile.write @params[:subscription][:picture].read
        tempfile.flush
        
        # Guess file format
        @params[:subscription][:picture].content_type.scan(/\/(.*)$/)
        
        avatar = Avatar.create_from_file tempfile, $1.strip
        if avatar.nil?
          flash[:warning] = "A problem occured during avatar upload"
        else
          @subscription.update_attribute(:avatar_id, avatar.id)
        end
      end
    end  
    redirect_to :action => 'index'
  end

  def add_blog
    check_user
    params[:blogs].each do |blog|
      unless blog.empty?
        begin
          # Create or find a feed using specified blog url
          feed = Feed.create_from_blog(blog)
          # If feed exists, connect it to user using subscription
          unless feed.nil?
            subscription = Subscription.create(["feed" => feed, "user" => @user, "avatar_id" => 1])
          end
          flash[:message] = "Se han a&ntilde;adido los feeds"
        rescue => err
          flash[:warning] = "A problem occured with a feed: #{err.message}"
        end
      end
    end
  end

  def delete_blog
    check_user
    @headers["Content-Type"] = "text/javascript"
    subscription = Subscription.find(params[:id])
    @deleted_blog = "blog_" << params[:id]
    subscription.destroy
  end
  
  def delete_all
    check_user
    @user.subscriptions.each do |sub|
      sub.destroy
    end
    redirect_to :action => 'index'
  end

  def edit_blog
    check_user
    @headers["Content-Type"] = "text/javascript"
    @subscription = Subscription.find(params[:id])
    @return = params[:return]
  end

  def update_feeds
    Feed.update_all
    flash[:message] = "Feeds updated"
    redirect_to :action => 'index'
  end

  def update_feed
    check_user
    @feed = Feed.find params[:id]
    @feed.refresh unless @feed.nil?
    flash[:message] = "#{feed.title} updated"
    redirect_to :action => 'index'
  end

  def display_feevy_code
    check_user
    @headers["Content-Type"] = "text/javascript"
    style = ""
    style = "/" << params[:style] unless params[:style] == "dark"
    script = "&lt;script type='text/javascript' src='http://www.feevy.com/code/#{@user.id}#{style}'&gt;&lt;/script&gt;"
    render :text => script
  end

  def update_opt_display_sub
    check_user
    @user.update_attribute :opt_displayed_subscriptions, params[:display_feevy]
    render :nothing => true
  end
  

  def choose_user_lang
    check_user
    @user.update_attribute :opt_lang, params[:lang]
    render :nothing => true
  end

  def tag_blog
    check_user
    @headers["Content-Type"] = "text/javascript"
    @subscription = Subscription.find(params[:id])
    if params[:tag_input]
      @tag_list = params[:tag_input].gsub(/([^,])\s/, '\1, ')
      @subscription.tag_list = @tag_list
      @subscription.save
      @subscription = @subscription.reload
    end
  end
  
  def export_opml
    check_user
    @subscriptions = @user.subscriptions
    @subscriptions.delete_if {|sub| sub.feed.nil?}
    render :file => "manage/feevy_opml", :use_full_path => true
  end
  
  protected
  def check_user
    unless @user
      flash[:warning] = "Your session has expired"
      redirect_to :controller => "auth", :action => "login"
    end
  end
end
