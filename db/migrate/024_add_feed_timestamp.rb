class AddFeedTimestamp < ActiveRecord::Migration
  def self.up
    begin
      add_column :feeds, :created_at, :datetime
    rescue
    end
    begin
      add_column :feeds, :updated_at, :datetime
    rescue
    end
  end

  def self.down
  end
end
