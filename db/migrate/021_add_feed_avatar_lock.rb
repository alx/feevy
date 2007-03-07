class AddFeedAvatarLock < ActiveRecord::Migration
  def self.up
    remove_column :subscriptions, :avatar_locked
    add_column :feeds, :avatar_locked, :integer, :default => 0
  end

  def self.down
  end
end
