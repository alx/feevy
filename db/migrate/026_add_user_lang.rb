class AddUserLang < ActiveRecord::Migration
  def self.up
    add_column :users, :opt_lang, :string, :default => "en-EN"
  end

  def self.down
    remove_column :users, :opt_lang
  end
end
