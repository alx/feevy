class ChangeUserSchema < ActiveRecord::Migration
  def self.up
    
    drop_table :users
    
    create_table "users", :force => true do |table|
      # table.column :id, :integer // this is implicit (when using create_table)
      table.column :login, :string, :limit => 80
      table.column :cryptpassword, :string, :limit => 40
      table.column :validkey, :string, :limit => 40
      table.column :email, :string, :limit => 100
      table.column :newemail, :string, :limit => 100
      table.column :ipaddr, :string
      table.column :created_at, :datetime
      table.column :updated_at, :datetime
      table.column :confirmed, :integer
      table.column :domains, :string
      table.column :image, :string
      table.column :firstname, :string
      table.column :lastname, :string
      table.column :registration_stage, :integer, :default => 0
      table.column :country, :string
    end
  end

  def self.down
    
    drop_table :users
    
    create_table "users", :force => true do |t|
      t.column "email", :string, :limit => 100
      t.column "crypted_password", :string, :limit => 40
      t.column "salt", :string, :limit => 40
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "activation_code", :string, :limit => 40
      t.column "activated_at", :datetime
      t.column "country", :string
      t.column "registration_stage", :integer
      t.column "first_name", :string
      t.column "last_name", :string
      t.column "password_reset", :integer
    end
  end
end
