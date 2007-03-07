class AddFeedCharset < ActiveRecord::Migration
  def self.up
    add_column :feeds, :charset, :string, :default => "utf-8"
  end

  def self.down
    remove_column :feeds, :charset
  end
end
