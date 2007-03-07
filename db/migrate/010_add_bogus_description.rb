class AddBogusDescription < ActiveRecord::Migration
  def self.up
    add_column :feeds, :bogus_description, :string
  end

  def self.down
    remove_column :feeds, :bogus_description
  end
end
