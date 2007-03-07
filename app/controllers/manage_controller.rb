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
        @user.update_attributes(:registration_stage => 2)
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
      params[:blogs].each do |blog|
        # Do not process this blog if it's empty
        unless blog.empty?
          begin
            # Create or find a feed using specified blog url
            logger.debug "create from blog: #{blog}"
            feed = Feed.create_from_blog(blog)
            # If feed exists, connect it to user using subscription
            unless feed.nil?
              logger.debug "feed #{feed.id}: #{feed.link}"
              subscription = Subscription.create_default
              feed.subscriptions << subscription
              @user.subscriptions << subscription
            end
            flash[:message] = "Feeds has been added to your Feevy list."
          rescue => err
            flash[:warning] = "A problem occured with a feed: #{err.message}"
          end
        end
      end

      @user.update_attributes(:registration_stage => 1)

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
    @subscription = Subscription.find(params[:id])
  end

  def select_avatar
    check_user
    @update_avatar = params[:update_avatar]
    @subscription = Subscription.find(params[:id])
    @subscription.update_attributes(:avatar_id => params[:avatar_id])
  end

  def change_avatar
    check_user
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
        require 'tempfile'

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
            subscription = Subscription.create_default
            feed.subscriptions << subscription
            @user.subscriptions << subscription
          end
          flash[:message] = "Se han a&ntilde;adido los feeds"
        rescue => err
          flash[:warning] = "A problem occured with a feed: #{err.message}"
        end
      end
    end
  end

  def add_another_blog
    check_user
  end

  def add_more_blog
    check_user
  end

  def delete_blog
    check_user
    subscription = Subscription.find(params[:id])
    @deleted_blog = "blog_" << params[:id]
    @deleted_bogus = "bogus_" << params[:id] if subscription.feed.bogus == true 
    subscription.destroy
  end

  def edit_blog
    check_user
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
    style = ""
    style = "/" << params[:style] unless params[:style] == "dark"

    script = "<script type='text/javascript' src='http://www.feevy.com/code/#{@user.id}#{style}'></script>"
    render :text => HTMLEntities.encode_entities(script)
  end

  def update_opt_display_sub
    check_user
    @user.update_attribute :opt_displayed_subscriptions, params[:display_feevy]
    render :nothing => true
  end
  
  protected
  def check_user
    unless @user
      flash[:warning] = "Your session has expired"
      redirect_to :controller => "auth", :action => "login"
    end
  end
end
