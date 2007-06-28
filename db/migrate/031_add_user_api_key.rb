class AddUserApiKey < ActiveRecord::Migration
  def self.up
    begin
      add_column :users, :api_key, :string, :limit => 40
    rescue
    end
  end

  def self.down
  end
end
