require 'deprec/recipes'
require 'deprec/recipes/cache_svn'

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

set :domain, "www.feevy.com"
role :web, domain
role :app, domain
role :db,  domain, :primary => true
role :scm, domain

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "feevy"
set :deploy_to, "/var/www/apps/#{application}"

# XXX we may not need this - it doesn't work on windows
set :user, "feevy"
set :repository, "svn+ssh://#{user}@#{domain}#{deploy_to}/repos/trunk"
set :rails_env, "production"

# Automatically symlink these directories from current/public to shared/public.
set :app_symlinks, %w{images/avatars}

desc "Link avatar directory"
task :after_update do
  symlink_public
end

set :repository_cache, "#{shared_path}/svn_trunk/"

# =============================================================================
# APACHE OPTIONS
# =============================================================================
# set :apache_server_name, domain
# set :apache_server_aliases, %w{alias1 alias2}
# set :apache_default_vhost, true # force use of apache_default_vhost_config
# set :apache_default_vhost_conf, "/etc/httpd/conf/default.conf"
# set :apache_conf, "/etc/httpd/conf/apps/#{application}.conf"
# set :apache_ctl, "/etc/init.d/httpd"
# set :apache_proxy_port, 8000
# set :apache_proxy_servers, 2
# set :apache_proxy_address, "127.0.0.1"
# set :apache_ssl_enabled, false
# set :apache_ssl_ip, "127.0.0.1"
# set :apache_ssl_forward_all, false
# set :apache_ssl_chainfile, false


# =============================================================================
# MONGREL OPTIONS
# =============================================================================
# set :mongrel_servers, apache_proxy_servers
# set :mongrel_port, apache_proxy_port
# set :mongrel_address, apache_proxy_address
# set :mongrel_environment, "production"
# set :mongrel_config, "/etc/mongrel_cluster/#{application}.conf"
# set :mongrel_user, user
# set :mongrel_group, group

# =============================================================================
# MYSQL OPTIONS
# =============================================================================


# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:keys] = %w(/Users/alx/.ssh/id_rsa)
# ssh_options[:port] = 25

# =============================================================================
# AVATARS TASKS
# =============================================================================

desc "Install avatars from old platform"
task :setup_avatars do
  old_dir = "/home/wwwfeev/feevy/public/images/avatars/"
  new_dir = "#{shared_path}/public/images/avatars"
  run "mkdir -p #{new_dir}"
  (1..9).each do |index|
    run "cp #{old_dir}#{index}* #{new_dir}"
  end
end

# =============================================================================
# LOG TASKS
# =============================================================================

desc "Analyze Rails Log instantaneously" 
task :pl_analyze, :roles => :app do
  run "pl_analyze #{shared_path}/log/#{rails_env}.log" do |ch, st, data|
    print data
  end
end

desc "Run rails_stat" 
task :rails_stat, :roles => :app do
  stream "rails_stat #{shared_path}/log/#{rails_env}.log" 
end

desc "Show monit summary"
task :monit_summary do
  sudo "monit summary" do |channel, stream, data|
    puts data if stream == :out
    if stream == :err
      puts "[err: #{channel[:host]}] #{data}"
      break
    end
  end
end

# =============================================================================
# BACKROUNGDRB TASKS
# =============================================================================

desc "Start backgroundrb"
task :start_backgroundrb do
  sudo "backgroundrb start"
end

desc "stop backgroundrb"
task :stop_backgroundrb do
  sudo "backgroundrb stop"
end