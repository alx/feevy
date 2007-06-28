class AddPingTotalCount < ActiveRecord::Migration
  def self.up
    add_column :pings, :total_count, :integer, :default => 0
    change_column :pings, :current_offset, :integer, :default => 0
    pingers = ["Master Ping", "unknown"]
    pingers.each do |pinger|
      unless Ping.find(:first, :conditions => ["name = ?", pinger])
        Ping.create(:name => pinger)
      end
    end
  end

  def self.down
    remove_column :pings, :total_count
  end
end
