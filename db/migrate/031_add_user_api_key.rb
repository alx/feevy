class AddUserApiKey < ActiveRecord::Migration
  def self.up
    add_column :users, :api_key, :string, :limit => 40
  end

  def self.down
  end
end
