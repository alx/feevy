class AddPostUpdatedAt < ActiveRecord::Migration
  def self.up
    add_column :posts, :updated_at, :datetime
  end

  def self.down
  end
end
