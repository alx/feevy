class AddFeedTimestamp < ActiveRecord::Migration
  def self.up
    add_column :feeds, :created_at, :datetime
    add_column :feeds, :updated_at, :datetime
  end

  def self.down
  end
end
