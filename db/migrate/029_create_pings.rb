class CreatePings < ActiveRecord::Migration
  def self.up
    create_table :pings do |t|
      t.column :name, :text
      t.column :current_offset, :integer
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :pings
  end
end
