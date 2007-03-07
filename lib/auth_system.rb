require_dependency "user"

module AuthSystem 

  include AuthHelper

  # store current uri in the ccokies
  # we can return to this location by calling return_location
  def store_location
    cookies[:return_to] = {:value => @request.request_uri, :expires => nil }
  end

  protected
  
	def del_location
    cookies[:return_to] = {:value => nil, :expires => nil }
	end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if cookies[:return_to].nil?
      redirect_to default
    else
      redirect_to_url cookies[:return_to]
      cookies[:return_to] = nil
    end
  end

  def require_auth(credentials = nil)
		auth_intercept('login') unless user_logged_in? 
		access_granted = false

    case credentials.class.to_s
		when 'NilClass'		# simple authentication
			access_granted = user_logged_in?
		when 'Array'	    # check against any of the credentials
			credentials.each { |cred|
				if @user.access_granted_for?(cred); access_granted = true; break; end
      }
		else							# check against all of the credentials
			access_granted = @user.access_granted_for?(credentials)
		end

		auth_intercept('denied') unless access_granted == true
    return access_granted
	end

  # insert interceptor action before current action 
	def auth_intercept(interceptor_action = 'login')
		store_location
    unless auth_app_interceptor(interceptor_action)
		  flash[:warning] = "You lack credentials to access this page"
		  redirect_to auth_url(:action => interceptor_action)
    end
		throw :abort
  end

  # override auth_intercept behavior on authorization failures
  # return true to override the default action, false otherwise
  def auth_app_interceptor(interceptor_name)
#     redirect_to "http://je.suis.perdu.com/"
#     return true
			return false
  end

  # override if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
		flash[:warning] = "You don't have the right to access this page"
    redirect_to auth_url(:action => 'denied')
  end  

	def app_config
		@app ||= YAML.load_file("#{RAILS_ROOT}/config/auth_generator.yml").symbolize_keys
		User.config @app
	end

	def ident
		require_dependency "user"
		if cookies[:user]
			# fromString may return nil!
			@user =	User.fromString(cookies[:user])
		end

		if @user.nil?
			@user = User.new
			@user.ident = false
		end

		# !!! Leave that true !!!
		true
	end

end
