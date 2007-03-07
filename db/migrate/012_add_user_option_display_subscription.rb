class AddUserOptionDisplaySubscription < ActiveRecord::Migration
  def self.up
    add_column :users, :opt_displayed_subscriptions, :string, :default => "all"
  end

  def self.down
    remove_column :users, :opt_displayed_subscriptions
  end
end
