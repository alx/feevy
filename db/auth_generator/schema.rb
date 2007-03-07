ActiveRecord::Schema.define do

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
 end

 #create_table "articles", :force => true do |table|
   # table.column :id, :integer // this is implicit (when using create_table)
	 #  table.column :title, :string
	 #  table.column :body, :string
	 #end

end
