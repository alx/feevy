class SubscriptionJustAdded < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :just_added, :integer, :default => 1
    
    @subscriptions = Subscription.find :all
    @subscriptions.each do |sub|
      sub.update_attribute 'just_added', 0
    end
  end

  def self.down
    remove_column :subscriptions, :just_added
  end
end
