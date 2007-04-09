class CreateFeevies < ActiveRecord::Migration
  def self.up
    create_table :feevies do |t|
    end
  end

  def self.down
    drop_table :feevies
  end
end
