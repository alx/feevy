class DefaultSubAvatar < ActiveRecord::Migration
  def self.up
    change_column :subscriptions, :avatar_id, :integer, :default => 1
  end

  def self.down
  end
end
