class AuthadminController < ApplicationController
	layout :theme_layout
	
	def index
		require_auth 'admin'
		list
		render :action => 'list'
	end

	def list
		require_auth 'admin'

		if params[:post] and params[:post][:s]
			@user_pages, @users = paginate :user, :per_page => 20, :order_by =>'id desc', 
			:conditions => ['login like ? or email like ? or firstname like ? or lastname like ?', 
				'%' + params[:post][:s].gsub(/[']/) { '\\'+$& } + '%',
				'%' + params[:post][:s].gsub(/[']/) { '\\'+$& } + '%',
				'%' + params[:post][:s].gsub(/[']/) { '\\'+$& } + '%',
				'%' + params[:post][:s].gsub(/[']/) { '\\'+$& } + '%']
		elsif params[:id]
			@user_pages, @users = paginate :user, :per_page => 20, :order_by =>'id desc', 
			:conditions => ['domains like ?', '%' + params[:id].gsub(/[']/) { '\\'+$& } + ',%']
		else
			@user_pages, @users = paginate :user, :per_page => 20, :order_by =>'id desc'
		end
	end

	# Delete the user
	def deluser
		require_auth 'admin'
		if @request.xhr?
			@edituser = User.find_first(["id = ?",params[:id]])
			if @edituser and params[:id].to_i > 1
				@edituser.destroy
			end
		end
		render :nothing=>true
	end

	def edituser
		require_auth 'admin'
		@edituser = User.find_first(["id = ?",params[:id]])
		if @request.post?
  		if not @edituser.nil?
  			@edituser.firstname = @params[:edituser][:firstname]
  			@edituser.lastname = @params[:edituser][:lastname]
  			@edituser.login = @params[:edituser][:login]
  			@edituser.confirmed = @params[:edituser][:confirmed]
				if @params[:delete_image].to_i == 1
					@edituser.image = nil
					expire_page auth_url(:action => 'image', :id => "#{@edituser.login}.png")
				end
  			if not @params[:edituser][:password].nil? and 
  				@params[:edituser][:password] == @params[:edituser][:passwordbis] and
  				@params[:edituser][:password] != ""
  				@edituser.password = @params[:edituser][:password]
  			end
  			@edituser.email = @params[:edituser][:email]
  
  			notice = ""
  			if @params[:edituser][:image] and not @params[:edituser][:image] == "" and 
					not @params[:edituser][:image].original_filename.empty?
  				if not @params[:edituser][:image].content_type.chomp =~ /^image/
  					notice += "Your picture isn't an image !" 
  				else
  					require 'GD'
  					require 'tempfile'
  
						tempfile = Tempfile.new('tmp')
  					tempfile.write @params[:edituser][:image].read
  					tempfile.flush
  					File::open(tempfile.path, mode="r") { |f|
  						img = nil
  						case @params[:edituser][:image].content_type.chomp
  						when "image/jpeg" then
  							img = GD::Image.newFromJpeg(f)
  						when "image/png" then
  							img = GD::Image.newFromPng(f)
  						end
  
  						if not img.nil?
  							if img.bounds[0] == @app[:icon_size] and img.bounds[1] == @app[:icon_size]
  								@edituser.image = img.pngStr  # = @params[:post][:picture].read
  							else
  								notice += "Your image isn't #{@app[:icon_size]}x#{@app[:icon_size]}!"
  							end
  							img.destroy
  						end
  					}
  				end
					expire_page auth_url(:action => 'image', :id => "#{@edituser.login}.png")
  			end
  
				if not notice.empty?
					flash.now['notice'] = notice
				else
					if  not @edituser.save
						flash.now['notice'] = "An error occured while saving the user."
					else
						flash.now['notice'] = "Informations have been stored."
					end
				end
  		end
		end
	end

	# Used to edit domains, add new domain.
	def editdomains
		require_auth 'admin'
		@edituser = User.find_first(["id = ?",@params[:post][:id]])
		if not @edituser.nil?
			if not @params[:post][:domain].nil? and 
				@params[:post][:domain] =~ /^\w+$/ and
				@params[:post][:domain_level] =~ /^\d+$/
				#if @edituser.domains.has_key?(@params[:post][:domain].upcase)
				#	flash.now['note'] = "This user is already in this domain. Delete it first!"
				#else
				@edituser.domains[@params[:post][:domain].upcase] = @params[:post][:domain_level]
				if not @edituser.save
					flash.now['note'] = "An error occured while saving the user"
				end
				#end
			else
				flash.now['note'] = "You must enter a domain name using only ASCII"
			end
		end
		render :layout => false
	end

	# Used for new user
	def newuser
		require_auth 'admin'
	end

	# Used to create user
	def createuser 
		require_auth 'admin'
		if params[:post][:password] == params[:post][:passwordbis]
			@newuser = User.new
			@newuser.login = params[:post][:login]
			@newuser.password = params[:post][:password]
			@newuser.confirmed = 1
			@newuser.ipaddr = @request.remote_ip
			@newuser.domains = { 'USERS' => 1 }
			@newuser.email = params[:post][:email]
			if @newuser.save
				if params[:post][:notify].to_i == 1
					Notification.deliver_admin_newuser(@newuser,params[:post][:password], @app)
					flash.now['notice'] = "The user has been saved, a notify has been sent"
				else
					flash.now['notice'] = "The user has been saved"
				end
			else
				flash.now['notice'] = "An error occured to save the user"
			end
		else
			flash.now['notice'] = "Password don't match!"
		end
		
		if @request.xhr?
			render :layout => false
		end
	end

	# Used to delete a domain
	def deldomain
		require_auth 'admin'
		if not params[:id].nil?
			id,domain = params[:id].split(',',2)
			@edituser = User.find_first(["id = ?",id])
			if @edituser.domains.has_key? domain
				if @edituser.login == @user.login and domain == "ADMIN"
					flash.now['note'] = "You can't remove yourself from admin!"
				elsif @edituser.id == 1 and domain == "ADMIN"
					flash.now['note'] = "You can't remove that user from admin!"
				else
					@edituser.domains.delete(domain)
					if not @edituser.save
						flash.now['note'] = "An error occured while saving the user"
					end
				end
			end
		end
		if @request.xhr?
			render :layout => false, :action => "editdomains"
		end
	end

 	protected
 	def this_auth
 		@app
 	end
 	helper_method :this_auth
 
 	def theme_layout
 		"../authadmin/theme/#{@app[:themeadmin]}/layout.rhtml"
 	end
end
