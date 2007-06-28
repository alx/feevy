class AddDefaultAvatar < ActiveRecord::Migration
  def self.up
    begin
      add_column :subscriptions, :avatar_url, :string, :default => "/images/hombre1.png"
    rescue
      change_column :subscriptions, :avatar_url, :string, :default => "/images/hombre1.png"
    end
    @subs = Subscription.find :all
    @subs.each do |subscription|
      subscription.update_attribute(:avatar_url, "/images/hombre1.png") if subscription.avatar_url.nil?
    end
  end

  def self.down
  end
end
