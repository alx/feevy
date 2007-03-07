class UserAddSetupStage < ActiveRecord::Migration
  def self.up
    add_column "users", "registration_stage", :integer
  end

  def self.down
    remove_column "users", "registration_stage"
  end
end
