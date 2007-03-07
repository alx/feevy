
class InitialMigration < ActiveRecord::Migration
  def self.up
      create_table "cached_feeds", :force => true do |t|
        t.column "href", :string
        t.column "title", :string
        t.column "link", :string
        t.column "feed_data", :text
        t.column "feed_data_type", :string
        t.column "http_headers", :text
        t.column "last_retrieved", :datetime
      end

      create_table "feeds", :force => true do |t|
        t.column "href", :string
        t.column "title", :string
        t.column "link", :string
        t.column "latest_post_title", :text
        t.column "latest_post_link", :text
        t.column "latest_post_description", :text
        t.column "latest_post_timestamp", :datetime
      end

      create_table "subscriptions", :force => true do |t|
        t.column "user_id", :integer
        t.column "feed_id", :integer
        t.column "avatar_url", :string
      end

      create_table "users", :force => true do |t|
        # t.column "login", :string, :limit => 40
        t.column "email", :string, :limit => 100
        t.column "crypted_password", :string, :limit => 40
        t.column "salt", :string, :limit => 40
        t.column "created_at", :datetime
        t.column "updated_at", :datetime
        t.column "activation_code", :string, :limit => 40
        t.column "activated_at", :datetime
        t.column "country", :string
      end
  end

  def self.down
    drop_table "cached_feeds"
    drop_table "feeds"
    drop_table "subscriptions"
    drop_table "users"
  end
end
