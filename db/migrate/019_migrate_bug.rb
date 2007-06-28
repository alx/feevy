class MigrateBug < ActiveRecord::Migration
  def self.up
    @feeds = Feed.find :all
    
    @feeds.each do |feed|
      if feed.bogus == true 
        Bug.create :level => Bug::ERROR,
                   :description => feed.bogus_description,
                   :feed_id => feed.id
      end
    end
    
    # remove_column :feeds, :bogus
    # remove_column :feeds, :bogus_description
  end

  def self.down
  end
end
