class AddPingLock < ActiveRecord::Migration
  def self.up
    add_column :pings, :lock, :integer, :default => 0
  end

  def self.down
  end
end
