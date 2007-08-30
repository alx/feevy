class FeedBogus < ActiveRecord::Migration
  def self.up
    add_column :feeds, :is_bogus, :integer, :default => 0
    add_column :feeds, :is_warning, :integer, :default => 0
    Feed.find(:all).each do |feed|
      warning = feed.has_warnings
      error = feed.has_error
      if warning and error
        feed.updates_attributes :is_bogus => 1, :is_warning => 1
      elsif warning
        feed.updates_attribute :is_warning, 1
      elsif error
        feed.updates_attribute :is_bogus, 1
      end
    end
  end

  def self.down
  end
end
