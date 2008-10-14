class UniqueFeed < ActiveRecord::Migration
  def self.up
    add_index :feed, :link, :unique => true
  end

  def self.down
    remove_index :feed, :column => :link
  end
end
