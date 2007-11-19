class UserController < ApplicationController

  # say something nice, you goof!  something sweet.
  def index
    require_auth
  end
  
  def reset_password
    begin
       @user = User.find params[:id]
    rescue ActiveRecord::RecordNotFound => e
      flash[:message] = "You have not asked to reset your password"
      redirect_back_or_default(:controller => '/welcome', :action => 'index')
      return
    end
    
    # It should be thrown in previous Exception catcher
    unless @user.password_reset?
      flash[:message] = "You have not asked to reset your password"
      redirect_back_or_default(:controller => '/welcome', :action => 'index')
      return
    end
    # We should call change_password here
  end
  
  def change_password
    return unless request.post?
    
    @user = User.new(params[:user])
    
    logger.info "user password: " << @user.password
    # And changing password if it's not empty
    unless @user.password.nil? || @user.password.empty?
      unless @user.password == params[:user][:password_confirmation]
        # Incorrect password confirmation
        flash[:warning] = "Wrong confirmation password"
        return
      else  
        # Change current_user password
        current_user.password = @user.password
        current_user.password_reset = false
      end
    end
    
    # Save modifications
    current_user.save
    
    # We havn't got any error on saving
    if current_user.errors.empty?
      flash[:notice] = "Password resetted"
    # Some validation errors appear during saving
    else
      flash[:warning] = "Error while saving modifications:"
      current_user.errors.each_full { |msg| flash[:warning] << "<br>" << msg }
    end
  end

  def login
    return unless request.post?
    
    self.current_user = User.authenticate(
        params[:email], 
        params[:password])
        
    if current_user
      flash[:message] = "Logged in successfully"
      redirect_to :controller => 'manage'
    end
  end

  def forgot_password
    return unless request.post?
    
    @user = User.find :first, :conditions => ["email LIKE ?", params[:email]]
    
    if @user
      @user.password_reset = true
      @user.save
      PasswordRetriever::deliver_forgot_password(@user)
      flash[:message] = "We just sent you an email with your password"
    else
      flash[:warning] = "There is no account registered with such email address"
      flash[:actions] = [{:label => "cancel", :controller => "/welcome", :action => ""}]
      flash[:actions] << {:label => "try with another email", :controller => "user", :action => "forgot_password"}
    end 
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    @user.registration_stage = 0
    if @user.save
      flash[:message] = "Thanks for signing up!"
      redirect_to :controller => 'manage'
    end
  end
  
  def logout
    self.current_user = nil
    flash[:message] = "You have been logged out"
    redirect_to :controller => 'welcome'
  end
  
  # Invoked from email sent on user creation
  def activate
    @user = User.find_by_activation_code(params[:id])
    if @user and @user.activate
      self.current_user = @user
      flash[:message] = "Your account has been activated"
      redirect_to :controller => 'manage'
    end
  end
  
  def edit
    if request.post?
      require_auth
      if @user.update_attributes(params[:user])
        flash[:notice] = "Changes made"
        redirect_to :action => 'edit'
      else  
        flash[:warning] = "Error while saving modifications:"
        @user.errors.each_full { |msg| flash[:warning] << "<br>" << msg }
        redirect_to :action => 'index'
      end
    end
  end
  
  def feevy_rss
    @user = User.find params[:id]
    @entries = @user.generate_feevy(params[:tags])
    
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
    render :action => 'feevy_rss', :layout => false
  end

  
  def feevy
    # Generate cache_key
    cache_key = "feevy_#{params[:id]}"
    cache_key << "_#{params[:tags]}" if params[:tags]
    cache_key << "_#{params[:style]}" if params[:style]
    
    # Get entries from cache or generate entries if not found
    unless @feevy = CACHE.get(cache_key)
    
      @user = User.find(params[:id])
      @entries = @user.generate_feevy(params[:tags])
      
      # Define layout
      partial_badge = "user/badge/content/normal"
      partial_style = "user/badge/style/dark"
      
      case params[:style]
        when  "light", "liquid"
          partial_badge = "user/badge/content/light"
          partial_style = "user/badge/style/light"
        when "white"
          partial_badge = "user/badge/content/normal"
          partial_style = "user/badge/style/white"
      end
    
      partial_badge += "_" + @user.opt_lang.gsub('-','_')
    
      logger.debug "partial_style: #{partial_style}"
      logger.debug "partial_badge: #{partial_badge}"
    
      @style =  render_to_string(:partial => partial_style, :locals => { :id => params[:id]})
      @style = "" if params[:style] == "open-css"
      @content = render_to_string(:partial => partial_badge, :locals => { :id => params[:id], :entradas => @entries} )
      @feevy = [@content, @style]
      CACHE.set(cache_key, @feevy, 60*5)
    else
      @content = @feevy[0]
      @style = @feevy[1]
    end
    
    if request.env['HTTP_ACCEPT'] =~ /(application|text)\/(html|xhtml)/
      # render html version
      logger.debug @content.to_s
      render :layout => false
    else
      # render script version
      render :action => "feevy_script" 
    end
  end
  
  def feevy_script
    render :layout => false 
  end
end
