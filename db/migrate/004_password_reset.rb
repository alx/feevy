class PasswordReset < ActiveRecord::Migration
  def self.up
    add_column "users", "password_reset", :integer
  end

  def self.down
    remove_column "users", "password_reset"
  end
end
