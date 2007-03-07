module AuthHelper

	# For theme support. Idea from Typo.
	def search_paths(path)
		["#{path}/theme/#{this_auth[:theme]}/",
		]
	end

	def full_template_path(template_path, extension)
		template_path_dirs = template_path.split('/')
		dir = template_path_dirs[0]
		template_path_dirs.shift
		file = template_path_dirs.join('/')
		search_paths(dir).each do |path|
			themed_path = File.join(@base_path, path, "#{file}.#{extension}")
			return themed_path if File.exist?(themed_path)
		end
		super
	end

	# Taken from the webrick server
  module Utils
		if !const_defined? "RAND_CHARS"
			RAND_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
			"0123456789" +
			"abcdefghijklmnopqrstuvwxyz"
		end
    def random_string(len)
      rand_max = RAND_CHARS.size
      ret = ""
      len.times{ ret << RAND_CHARS[rand(rand_max)] }
      ret
    end
    module_function :random_string

  end

	# Show user informations using Ajax. Can be used on static pages / cached pages.
	def ajax_account_infos()
		txt = render(:partial => "auth/remotelogin", :layout => 'auth')
		"" + javascript_tag('function showloginform() {'+ update_element_function("accountinfo", :content => txt) +
				' document.getElementById(\'post_login\').focus();}') + "<!-- account info --> <div id=\"accountinfo\">"+
				link_to(auth_icon('buddy'), auth_url) + "</div>" + 
				javascript_tag("new Ajax.Updater('accountinfo', '/auth/remoteinfo', {asynchronous:true});")
	end

	# Show user information, don't use for static or cached page!
	def account_infos()
		txt = render(:partial => "auth/remotelogin", :layout => 'auth')
		"" + javascript_tag('function showloginform() {'+ update_element_function("accountinfo", :content => txt) +
		' document.getElementById(\'post_login\').focus();}') + "<!-- account info --> <div id=\"accountinfo\">"+
		render(:partial => "auth/remoteinfo", :layout => 'auth') + "</div>"
	end

	# Javascript version to show user information. Can be used on static pages / cached pages.
	def js_account_infos()
		txt = render(:partial => "auth/remotelogin", :layout => 'auth')
		"" + javascript_tag('function showloginform() {'+ update_element_function("accountinfo", :content => txt) +
		' document.getElementById(\'post_login\').focus();}') + "<!-- account info --> <div id=\"accountinfo\">" +
		"<script src=\"/auth/jsinfo\" type=\"text/javascript\"></script>"+
		'<script type="text/javascript">displayAccountInfo();</script>' + "</div>"
	end

  # store current uri in the ccokies
  # we can return to this location by calling return_location
  def store_location
    cookies[:return_to] = {:value => @request.request_uri, :expires => nil }
  end

  # Loading spinner indicator icon tag
  def spinner_tag(id = 'ident')
		image_tag('auth/spinner.gif', :id=>"#{id}_spinner", :align => 'absmiddle', :border=> 0, :style=> 'display: none;', :alt => 'loading...' )
	end

	# auth_generator's images tags
  def auth_icon(name)
		image_tag("auth/#{name}", :align => 'absmiddle', :border => 0, :alt => name)
  end

  # image tag for user
  def user_icon(login, email)
		if @app[:gravatar] == true
			site_url = @app[:url].chomp('/')
			default = html_escape "#{site_url}#{@app[:default_icon]}"
			url = "http://www.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(email)}&size=#{@app[:icon_size]}&default=#{default}"
			image_tag(url, :align => 'absmiddle', :width => @app['icon_size'], :border => 0, :alt => 'icon for ' + login)
		else
			image_tag(auth_url(:action => 'image', :id => login + '.png'), :align => 'absmiddle', :border => 0, :alt => 'icon for ' + login)
		end
  end

	# For the user form, if gravatar is used, no file upload!
	def user_info_icon_subpart
res = <<"EOF"
<tr><td>
  <label for="post_login">Your icon</label>
</td><td>
  <%= file_field "post", "picture", :size => 20, :class=>"form" %>
</td>
</tr>

<tr>
   <td colspan="2">
      Note: Your icon buddy must be <%= @app[:icon_size] %>x<%= @app[:icon_size]%> or it won't be saved.
   </td>
</tr>
EOF
		if @app[:gravatar] == true
			res = '<tr><td colspan="2">This website use <a href="http://www.gravatar.com">gravatar</a> icons.</td></tr>'
		end
		res
	end


  def user_logged_in?
		not @user.nil? and @user.ident == true
  end

end
