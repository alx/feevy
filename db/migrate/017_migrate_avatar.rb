class MigrateAvatar < ActiveRecord::Migration
  def self.up
    
    # Create new id relationship for avatars
    #add_column :subscriptions, :avatar_id, :integer
    #add_column :feeds, :avatar_id, :integer
    
    # Add default avatar for all feeds
    @feeds = Feed.find :all
    @feeds.each do |feed| 
      feed.update_attribute :avatar_id, 1
      #feed.discover_avatar_txt
    end
    
    # Fetch existing avatar for subscription and replace it with new avatar
    @subscriptions = Subscription.find :all
    @subscriptions.each do |sub|
      unless sub.avatar_url.nil?
        #tempfile = Tempfile.new('tmp')
        #tempfile.write open("#{RAILS_ROOT}/public" << sub.avatar_url).read
        #tempfile.flush
        
        # Guess file format
        #md = @params[:subscription][:picture].match /\.([^.]+)\z/
        #format = md ? md[1].downcase : nil
        
        #avatar = Avatar.create_from_file tempfile
        #File.delete("#{RAILS_ROOT}/public/#{sub.avatar_url}")
        #sub.update_attribute(:avatar_id, avatar.id) unless avatar.nil?
	sub.update_attribute(:avatar_id, 1)
      end
    end
    
    remove_column :subscriptions, :avatar_url
    remove_column :subscriptions, :avatar_by_user
  end

  def self.down
  end
end
