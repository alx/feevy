class CreateBugs < ActiveRecord::Migration
  def self.up
    create_table :bugs do |t|
      t.column :level, :integer
      t.column :status, :integer, :default => 0
      t.column :description, :text
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
      t.column :feed_id, :integer
    end
  end

  def self.down
    drop_table :bugs
  end
end
