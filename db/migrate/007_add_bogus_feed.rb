class AddBogusFeed < ActiveRecord::Migration
  def self.up
    add_column :feeds, :bogus, :integer, :default => 0
  end

  def self.down
    remove_column :feeds, :bogus
  end
end
