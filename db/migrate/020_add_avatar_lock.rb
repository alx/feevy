class AddAvatarLock < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :avatar_locked, :integer, :default => 0
  end

  def self.down
  end
end
