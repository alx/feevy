class AddPingerHash < ActiveRecord::Migration
  def self.up
    require 'digest/md5'
    add_column :pings, :hash, :string
    Ping.find(:all).each do |pinger|
      pinger.update_attribute :hash, Digest::MD5.hexdigest(rand(1000023).to_s)
    end
  end

  def self.down
    remove_column :pings, :hash
  end
end
