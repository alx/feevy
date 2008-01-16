class ApiController < ApplicationController
  
  # Display API help
  def index
  end
  
  # ***
  # API key
  # ***
  
  def view_key
    
    # retrieve user
    if params[:user_password] && params[:user_email]
      @user = User.find(:first, :conditions => ["email LIKE ? AND password LIKE ?", params[:user_email], params[:user_password]])
    else
      require_auth
    end
    
    # Retrieve api key if user exists
    if @user
      unless @api_key = @user.api_key
        @api_key = @user.generate_api_key
      end
    end
    render :layout => false
  end
  
  # Verify api_key, and send back username if api_key found in database
  def verify_key
    @user = get_api_user
    if @user.nil?
      render :nothing => true, :status => 503
    else
      render :layout => false
    end
  end
  
  # ***
  # Feed API
  # ***
  def list_feed
    # Expected params: api_key
    @user = get_api_user
    if @user.nil?
      render :nothing => true, :status => 503
    else
      @subscriptions = @user.subscriptions
      # Render RXML template
      render :layout => false
    end
  end
  
  def add_feed
    # Expected params: api_key, url
    @user = get_api_user
    if @user.nil? || params[:url].nil? || params[:url].empty?
      render :nothing => true, :status => 503
    else
      begin
        # Create or find a feed using specified blog url
        feed = Feed.create_from_blog(params[:url])
        # If feed exists, connect it to user using subscription
        unless feed.nil?
          subscription = Subscription.create(["feed" => feed, "user" => @user, "avatar_id" => 1])
        end
        @subscriptions = @user.subscriptions
        render :action => "list_feed"
      rescue => err
        render :nothing => true, :status => 500
      end
    end
  end
  
  def delete_feeds
    # Expected params: api_key, feed_id
    @user = get_api_user
    if @user.nil? || params[:feeds_id].nil?
      render :nothing => true, :status => 503
    else
      # delete list of feeds
      params[:feeds_id].split("+").each do |sub|
        logger.debug "delete feed #{sub}"
        Subscription.find(sub).destroy
      end
      @subscriptions = @user.subscriptions
      render :action => "list_feed"
    end
  end
  
  # ***
  # Avatar API
  # ***
  def edit_avatar
    # Expected params: api_key, feed_id, avatar_url
    @user = get_api_user
    
    begin
      raise Exception if @user.nil? || params[:feed_url].nil? || params[:avatar_url].nil?
      
      feed = Feed.find(:first, :conditions => ["link LIKE ?", params[:feed_url]])
      raise Exception if feed.nil?
      
      sub = Subscription.find(:first, 
                              :conditions => ["feed_id LIKE ? AND user_id LIKE ?",feed.id,@user.id])
      raise Exception if @sub.nil?
      
      if sub.feed.avatar_locked != 1
        # Find or create new avatar
        unless @avatar = Avatar.find(:first, :conditions => ["url LIKE ?", params[:avatar_url]])
          @avatar = Avatar.create(:url => params[:avatar_url])
        end
        sub.update_attribute(:avatar_id, @avatar.id)
      end
      
      @subscriptions = @user.subscriptions
      render :action => "list_feed"
    rescue
      render :nothing => true, :status => 503
    end
  end
  
  # ***
  # Tag API
  # ***
  def edit_tags
    # Expected params: api_key, feed_id, tag_list
    @user = get_api_user
    begin
      raise Exception if @user.nil? || params[:feed_url].nil? || params[:tag_list].nil?
      
      feed = Feed.find(:first, :conditions => ["link LIKE ?", params[:feed_url]])
      raise Exception if feed.nil?
      
      @sub = Subscription.find(:first, 
                              :conditions => ["feed_id LIKE ? AND user_id LIKE ?",feed.id,@user.id])
      raise Exception if @sub.nil?

      if params[:tag_list]
        logger.debug "params[:tag_list] #{params[:tag_list]}"
        @tag_list = params[:tag_list].gsub(/\+/, ', ')
        logger.debug "params[:tag_list] #{@tag_list}"
        @sub.tag_list = @tag_list
        @sub.save
      end
      @subscriptions = @user.subscriptions
    rescue
      render :nothing => true, :status => 503
    end
  end
  
  # ***
  # User API
  # ***
  def register_user
    # Expected params: api_key, user_password, user_email
    @user = get_api_user
    if @user.nil? || params[:user_password].nil? || params[:user_email].nil?
      render :nothing => true, :status => 503
    else
      @user = User.new("email" => params[:user_email],
                       "password" => params[:user_password],
                       "password_confirmation" => params[:user_password], 
                       "registration_stage" => 0)
      if @user.save
        @api_key = @user.generate_api_key
        render :action => "view_key", :layout => false
      else
        render :nothing => true, :status => 503
      end
    end
  end
  
  def user_options
    # Expected params: api_key, user_mail, displayed_feeds, lang
    @user = get_api_user
    if @user.nil?
      render :nothing => true, :status => 503
    else
      unless params[:user_mail].nil?
        @user.update_attribute :email, params[:user_mail]
      end
      unless params[:lang].nil?
        @user.update_attribute :opt_lang, params[:lang]
      end
      unless params[:displayed_feeds].nil?
        @user.update_attribute :opt_displayed_subscriptions, params[:displayed_feeds]
      end
      render :action => "list_feed"
    end
  end
  
  private
    def get_api_user
      unless params[:api_key].nil?
        return User.find(:first, :conditions => ["api_key LIKE ?", params[:api_key]])
      end
    end
end