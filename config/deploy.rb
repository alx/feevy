# =============================================================================
# ROLES
# =============================================================================

set :application, "feevy-git"
role :web, "feevy.com"
role :app, "feevy.com"
role :db, "feevy.com"

set :user, "wwwfeev"
set :rails_env, "production"

# Automatically symlink these directories from current/public to shared/public.
set :app_symlinks, %w{images/avatars}

# =============================================================================
# GIT OPTIONS
# =============================================================================

set :deploy_to, "/var/www/apps/#{application}"

set :repository,  "git://github.com/alx/feevy.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache

# =============================================================================
# MONGREL OPTIONS
# =============================================================================

set :mongrel_user, "wwwfeev"
set :mongrel_group, "wwwfeev"

# =============================================================================
# AVATARS TASKS
# =============================================================================

desc "Link avatar directory"
task :after_update do
  symlink_public
end

desc "Install avatars from old platform"
task :setup_avatars do
  old_dir = "/home/wwwfeev/feevy/public/images/avatars/"
  new_dir = "#{shared_path}/public/images/avatars"
  run "mkdir -p #{new_dir}"
  (1..9).each do |index|
    run "cp #{old_dir}#{index}* #{new_dir}"
  end
end

desc "Symlinks the :app_symlinks directories from current/public to shared/public"
task :symlink_public do
   if app_symlinks
     app_symlinks.each do |link|
       run "ln -nfs #{shared_path}/public/#{link} #{current_path}/public/#{link}"
     end
   end
end