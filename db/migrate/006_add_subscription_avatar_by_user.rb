class AddSubscriptionAvatarByUser < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :avatar_by_user, :string
  end

  def self.down
    remove_column :subscriptions, :avatar_by_user
  end
end
