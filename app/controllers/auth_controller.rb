class AuthController < ApplicationController
	caches_page	:image

  def index
		del_location
		@title = "User Interface"
		if @user.nil? or @user.ident == false
			redirect_to :action => "login"
		end
  end

	def image
		login = File.basename(params[:id], ".png")
		user = User.find_first(["login = ?", login])
		if user
			if not user.image.nil? and not user.image.empty?
				send_data(user.image,
				:filename=>"#{login}.png", :type => "image/png", :disposition=>"inline"
				)
			else
				send_file "#{RAILS_ROOT}/public#{@app[:default_icon]}", :type => "image/png", :disposition=>"inline", :streaming => false, :stream => false
			end
		end
		return nil
	end

	# Gets the account information through a javascript call
	def jsinfo
		render :layout=>false
		@headers["Content-Type"] = "text/plain" 
	end

	def remoteinfo
		if @request.xhr?
			render :layout=>false
		end
	end

	def resendnewemail
		require_auth
		@user.reload

		Notification.deliver_emailchange(@user, @app)
		flash['message'] = "We have resent you a mail."
		redirect_to :action => "info"

	end

	def info
		require_auth

		@title = "Your preferences"
		@newuser = nil

		@user.reload

		if @request.post?
			@newuser = User.find_first(["login = ? AND confirmed=1", @user.login])
			@newuser.lastname = @params[:post][:lastname]
			@newuser.firstname= @params[:post][:firstname]
			notice = ""
			if not @params[:post][:password].empty? and not @params[:post][:passwordbis].empty?
			   if @params[:post][:password] == @params[:post][:passwordbis]
				   @newuser.password = @params[:post][:password]
			   else
			      notice += "Your password don't match!"
 			   end
			end
			
			if @params[:post][:picture] and not @params[:post][:picture] == "" and
				not @params[:post][:picture].original_filename.empty?
				if not @params[:post][:picture].content_type.chomp =~ /^image/
					notice += "Your picture isn't an image !" 
					return false
				else

					tempfile = Tempfile.new('tmp')
					tempfile.write @params[:post][:picture].read
					tempfile.flush
					File::open(tempfile.path, mode="r") { |f|
						img = nil
						case @params[:post][:picture].content_type.chomp
						when "image/jpeg" then
							img = GD::Image.newFromJpeg(f)
						when "image/png" then
							img = GD::Image.newFromPng(f)
						when "image/pjpeg" then
							img = GD::Image.newFromJpeg(f)
						when "image/x-png" then
							img = GD::Image.newFromPng(f)
						end

						if not img.nil?
							if img.bounds[0] == @app[:icon_size] and img.bounds[1] == @app[:icon_size]
								@newuser.image = img.pngStr  # = @params[:post][:picture].read
							else
#								notice += "Your image isn't #{@app[:icon_size]}x#{@app[:icon_size]}!"
                aspect_ratio = img.width.to_f / img.height.to_f
                if aspect_ratio > 1.0
                  nHeight = @app[:icon_size]
                  nWidth  = @app[:icon_size] * aspect_ratio
                else
                  nWidth  = @app[:icon_size]
                  nHeight = @app[:icon_size] / aspect_ratio
                end                
                thumb = GD::Image.newTrueColor(@app[:icon_size], @app[:icon_size])
                img.copyResized(thumb, 0,0,0,0,nWidth, nHeight, img.width, img.height)
                @newuser.image = thumb.pngStr # = @params[:post][:picture].read
                thumb.destroy
							end
							img.destroy
						end
					}
				end
				expire_page :action => 'image', :id => "#{@newuser.login}.png"
			end
			
			sentemail = false
			if not @params[:post][:newemail].empty? and @params[:post][:newemail] != @user.email
        tmpuser = User.find_first(["email = ?",@params[:post][:newemail]])
        if tmpuser.nil?
          @newuser.newemail = @params[:post][:newemail]
					sentemail = true
          # @newuser.generate_validkey_email(@newuser.newemail)
          # 
          #           Notification.deliver_emailchange(@newuser, @app)
        else
          notice = "An account already uses this email address."
        end
			end

			if not notice.empty?
				flash.now['notice'] = notice
			else
				if not @newuser.nil? and @newuser.save
					flash.now['notice'] = "Your preferences have been saved.\n"

					if sentemail == true
						flash.now['notice'] = "We sent you a message, please check your mails."
					end

					self.saveSession(@newuser, @user.expire_at)
					@user = @newuser
					@user.reload
				else
					flash.now['warning'] = "An error occured while saving your preferences"
				end
			end
		end
	end

	def remotelogin
		case @request.method
		when :post
			if not @params[:post].nil? and not @params[:post][:login].nil?
				user = User.authenticate(@params[:post][:login], @params[:post][:password])
				if user
					@err = 0
					self.saveSession(user, @params[:post][:keepalive].to_i)
					#render :text => "Login successfull! <script type=\"text/javascript\">setTimeout(external_load, 2000);</script>", :layout => false
					render :layout => false
				else
					@err = 2 
					#render :text => "Wrong login or password! <script type=\"text/javascript\">setTimeout(external_load, 2000);</script>", :layout => false
					render :layout => false
				end
			else
				render :layout => false
			end
		end
	end

	def login
		case @request.method
		when :post
			if not @params[:post].nil?
				user = User.authenticate(@params[:post][:login], @params[:post][:password])
				if user
					self.saveSession(user, @params[:post][:keepalive].to_i)
					flash[:notice] = "Login successful."
					redirect_back_or_default :controller => "manage"
				else
					flash.now[:warning] = "Oops, unknown username or password. " \
					"Have you signed up yet?" " If you've forgotten your password, we can email it to you."
					@login = @params[:post][:login]
					@err = 2;
				end
			end
		end
	end

	def resendsignup
		if cookies[:email] and not cookies[:email].nil?
			@email = cookies[:email]
		elsif @request.post? and not @params[:post].nil? and not @params[:post][:email].empty?
			@email = @params[:post][:email]
		else
			@email = nil
		end

		if not @email.nil?
			user = User.find_first(["email = ? and validkey != 'NULL' and confirmed=0",@email])
			if user.nil?
				flash.now['warning'] = "There is no account pending with this email! "
				flash['warning'] << "Either your account has been confirmed, either you need to make a new one"
			else
				Notification.deliver_signup(user,@app)
				cookies[:email] = { :value => user.email, :expires => nil }
				flash['message'] = "We have sent a message to #{user.email}. "
				flash['message'] << "Please paste the validation key it includes."
				redirect_to :action => "confirm"
			end
		end
	end
  
  def signup
		if not @app[:allow_self_registration]
			flash[:notice] = "Account creation is disabled."
      redirect_to :action => "login"
		end

    if @request.post?
      if false #@params[:terms] != 9
        flash[:warning] = "You need to accept terms and conditions to create an account."
      else
  			@newuser = User.new(@params[:post])
  			@newuser.confirmed= 1
  			@newuser.ipaddr = @request.remote_ip
  			@newuser.domains = { 'USERS' => 1 }
  			@newuser.password=@params[:post][:password]

        if @newuser.save
  				if @newuser.id == 1
  					@newuser.domains = { 'USERS' => 1, 'ADMIN'=> 1 }
  					@newuser.save
  				end  
          self.saveSession @newuser
          redirect_to :controller => "manage"
  				#Notification.deliver_signup(@newuser, @app)
  				#cookies[:email] = { :value => @newuser.email, :expires => nil }
          #flash['message'] = "We have sent a message to #{@newuser.email}. "
  				#flash['message'] << "Please paste the validation key it includes."
          #redirect_to :action => "confirm"
        else
          flash.now['warning']  = "An error occured while creating this account."
        end
      end
		else
			if @user and @user.ident
				flash.now['message']  = "You already have an account and are authentified. Are you sure you want to create a new account ?"
			end
    end      
  end  
  
  def logout
		if not @user
      redirect_to :action => "index"
			return false
		end

		if @request.xhr?
			render :layout => false #, :text => "Thanks for your visit."
		end
		self.cancelSession()
		flash['message'] = "Thanks for your visit."
    redirect_to :controller => "welcome"
  end

  def confirm
		@email = ""
		if not params[:id].nil?
			@email,validkey = params[:id].split(',',2)
		end

		if @request.post? and @params[:user][:validkey]
			validkey = @params[:user][:validkey]
			@email = @params[:user][:email]
		end

    if not validkey.nil? and not @email.empty?
      user = User.find_first(["email = ?",@email])

      if not user.nil? and user.validkey == validkey
        # User is confirming his account
        if not user.confirmed?
          user.confirmed= 1
          user.validkey = nil

          if user.save
            cookies[:email] = nil
            self.saveSession user
            flash[:message] = "Your account is confirmed. Please take some time to setup your preferences."
            redirect_to :action => "info"
          else
            flash[:warning] = "An error occured while saving your account"
          end
        # The user is asking for an email address change
        elsif user.confirmed? and not user.newemail.nil?
          if user.class.email_change_isvalid?(user.newemail, validkey)
            user.email = user.newemail
            user.newemail = nil
            user.validkey = nil
            if user.save
              self.saveSession(user, @user.expire_at)
              flash[:notice] = "Your email has been changed."
              redirect_to :action => "info"
            else
              flash[:warning] = "An error occured while saving your account."
            end
          else
            flash.now[:warning] = "This validation key is incorrect."
          end
        end
      else
        flash.now[:warning] = "This validation key is incorrect. Maybe you already confirmed your account?"
      end
    end

		if cookies[:email] and not cookies[:email].nil?
			@email = cookies[:email]
		elsif not @params[:user].nil? and @params[:user][:email]
			@email = @params[:user][:email]
		end
  end

  def lostpassword
		if @user and @user.ident
			@user.generate_validkey
			@user.save

			Notification.deliver_forgot(@user, @app)
			flash['notice']  = "We sent you a message, please check your mails."
			redirect_back_or_default :action => "index"
		end

		if @request.post? and @params[:post][:email]
			@newuser = User.find_first(["email = ?",@params[:post][:email]])
			if not @newuser.nil?
				@newuser.generate_validkey
				if @newuser.save
					Notification.deliver_forgot(@newuser, @app)
					flash[:notice]  = "We sent you a message, please check your mails."
					redirect_to :action => "login" 
				else    
					flash[:notice]  = "An error occured while saving informations."
					logger.info "An error occured while saving user informations."
				end     
			else    
				flash[:notice] = "Couldn't find an account with this email address."
			end     
		else    
			if @user
				@email = @user.email
			else    
				@email = ""
			end     
		end


  end

	def reset
		if @request.post? and not @params[:post].nil?
			@login = @params[:post][:login]
		elsif not @params[:login].nil?
			@login = @params[:login]
		else
			@login = ""
		end

		if @request.post? and not @params[:post].nil?
			@validkey = @params[:post][:validkey]
		elsif not @params[:validkey].nil?
			@validkey = @params[:validkey]
		else
			@validkey = ""
		end

		if not params[:id].nil?
			@login,@validkey = params[:id].split(',',2)
		end
		
		# If validation key is wrong, we leave right now
		user = User.find_first(["login = ?",@login])
		if user and user.validkey != @validkey
			flash['notice']  = "Your validation key is incorrect, please reask for your password."
			redirect_back_or_default :action => "lostpassword"
		end
		
		if @request.post?
			if @params[:post][:password] != @params[:post][:passwordconf]
				flash.now['notice'] = "Your passwords don't match!"
			else
				# Dont need this verification, but who knows... :]
				if user.validkey == @validkey
					user.password = @params[:post][:password]
					user.confirmed = 1 # Just in case...
					if user.errors.count == 0 and user.save
						user.validkey = nil
						user.save
						cookies[:email] = nil
						self.saveSession user
						flash['notice'] = "Your password has been changed."
						redirect_back_or_default :action => "welcome"
					else
						# There is a problem, we give the view access to this informations
						flash.now['notice'] = "There were an error while saving your new password."
						@newuser = user
					end
				end
			end
		end
	end
    
  def welcome
  end

	def denied
		render :layout => false
	end

	protected

	def saveSession(user, keepalive=nil)
		if not keepalive.nil? and keepalive > 0
			if keepalive == 1
				cookies[:user] = { 
					:value => user.sessionstring(60.days.from_now),
					:expires => 60.days.from_now 
				}
			else
				cookies[:user] = { 
					:value => user.sessionstring(60.days.from_now),
					:expires => Time.at(keepalive)
				}
			end
		else
			cookies[:user] = { 
				:value => user.sessionstring,
				:expires => nil
			}
		end
	end

	def cancelSession
		cookies[:user] = nil
		@user = User.new
	end

 	def this_auth
 		@app
 	end
 	helper_method :this_auth
 
 	def theme_layout
 		"../auth/theme/#{@app[:theme]}/layout.rhtml"
 	end
  
end
