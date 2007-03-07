class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars do |t|
      t.column :name, :string
      t.column :url, :string
    end
    Avatar.create :name => "hombre_1", :url => "http://www.feevy.com/images/hombre1.png"
    Avatar.create :name => "hombre_2", :url => "http://www.feevy.com/images/hombre2.png"
    Avatar.create :name => "hombre_3", :url => "http://www.feevy.com/images/hombre3.png"
    Avatar.create :name => "hombre_4", :url => "http://www.feevy.com/images/hombre4.png"
    
    Avatar.create :name => "mujer_1", :url => "http://www.feevy.com/images/mujer1.png"
    Avatar.create :name => "mujer_2", :url => "http://www.feevy.com/images/mujer2.png"
    Avatar.create :name => "mujer_3", :url => "http://www.feevy.com/images/mujer3.png"
    Avatar.create :name => "mujer_4", :url => "http://www.feevy.com/images/mujer4.png"
  end

  def self.down
    drop_table :avatars
  end
end
