class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.column :title, :string
      t.column :url, :string
      t.column :description, :text
      t.column :created_at, :timestamp
      t.column :feed_id, :integer
    end
  end

  def self.down
    drop_table :posts
  end
end
