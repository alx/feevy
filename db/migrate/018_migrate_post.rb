class MigratePost < ActiveRecord::Migration
  def self.up
    @feeds = Feed.find :all
    
    @feeds.each do |feed|
      Post.create :title => feed.latest_post_title,
                  :url => feed.latest_post_link,
                  :description => feed.latest_post_description,
                  :feed_id => feed.id
    end
    
    # remove_column :feeds, :latest_post_title
    #     remove_column :feeds, :latest_post_link
    #     remove_column :feeds, :latest_post_description
    #     remove_column :feeds, :latest_post_timestamp
  end

  def self.down
  end
end
