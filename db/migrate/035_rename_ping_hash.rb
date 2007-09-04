class RenamePingHash < ActiveRecord::Migration
  def self.up
    rename_column :pings, :hash, :password
  end

  def self.down
    rename_column :pings, :password, :hash
  end
end
