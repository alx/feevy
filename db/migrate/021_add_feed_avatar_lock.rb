class AddFeedAvatarLock < ActiveRecord::Migration
  def self.up
    begin 
      remove_column :subscriptions, :avatar_locked
    rescue
    end
    
    begin 
      add_column :feeds, :avatar_locked, :integer, :default => 0
    rescue
      change_column :feeds, :avatar_locked, :integer, :default => 0
    end
  end

  def self.down
  end
end
