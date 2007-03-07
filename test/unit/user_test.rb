require File.dirname(__FILE__) + '/../test_helper'

require 'user'

###
### Search XXX for a job ;o)
###

class UserTest < Test::Unit::TestCase

  fixtures :users

  # define the regex for a correct email address
  GOOD_EMAIL = '^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$'

  def setup
    # get jane, our confirmed user
		@app_config = {'crypt_method' => 'SHA1'}
		User.config @app_config
    @user = User.find(126)
  end

#  def test_fixtures_ok
#		# Hint: here are the users you can test with
#    assert_equal User.count, 4
#    assert_equal @users["dummy_user"]["id"], 123			# nil
#    assert_equal @users["admin_user"]["id"], 124			# admin
#    assert_equal @users["new_user"]["id"], 125				# joe
#    assert_equal @users["confirmed_user"]["id"], 126	# jane
#  end

  def test_save_new_user
    # we want a login, an email and a name
		joe = User.new({
							:login => "unique_login",
							:email => "unique_login@example.com",
							:firstname => "any",
							:lastname => "user"
					})
    # those are taken care of inside the controller
    joe.ipaddr = "1.2.3.4"
    joe.newemail = nil
    joe.confirmed = 0
		joe.domains = { 'USERS' => 1 }
		joe.password= "joepass"
    # before_create
		# joe.generate_validkey
    # before_save
		# joe.domains = User.domain2str(joe.domains)
		# joe.password = User.sha1("somepass")
    # do save
    assert joe.save, "something rotten... " + joe.inspect
  end

	def test_valid_login   
    # login must be between 3 and 40 characters
		@user[:login] = "a"
    assert !@user.save, "login too short"
    @user[:login] = "ab"
    assert !@user.save, "login too short"
    @user[:login] = 41.times { "c" }.to_s
    assert !@user.save, "login too long"
    @user[:login] = "jane"
    assert @user.save, "jane got back her login " + @user.inspect
    # login must be unique 
		@user[:login] = User.find('125').login
    assert !@user.save, "duplicate login"
	end

  def test_invalid_login
    # XXX regex against some invalid logins. What is an appropriate login? Can it start with a space?
    bad_strings = [ "", "1", "a", "ab", " oo", "1st", "ha!ha!ha!", "ha? F##K", "<%boo%>", User.find('125').login ]
		bad_strings.each do |bad|
			@user[:login] = bad
      assert !@user.save, "failed login: " + bad 
    end   
  end

	def test_valid_email
    joe = User.find('125')
    assert_match /#{GOOD_EMAIL}/, joe.email, "email must match format"
    joe.email = @user[:email]
    assert !joe.save, "email must be unique"
#		test_invalid_email_too_long
  end
#
  def test_invalid_email_too_long
  	@user[:email] = ("a" * 100) + "@too-long.com"
    assert !@user.save, "oops: " + @user.email
  end
#  
  def test_invalid_email_format
    good_email = '^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$'
    bad_strings = [ '', 'foo', 'foo@bar', '1@2', 'foo@bar.notvalid', '@foo', 'foo@', 'foo.bar.baz', "looks.like@it's.good?", 'looks.like@is..wrong' ]
    for bad in bad_strings do 
			assert bad !=~ /#{good_email}/
		end
  end
#
#  def test_valid_password
#    # functional test? password is hashed in model
#  end
#
  def test_valid_ipaddr
    # XXX assert_match real regex
		assert @user[:ipaddr].length<=15
		@user[:ipaddr] = '123.123.123.123.456'
		assert !@user.save
  end
#
  def test_valid_validkey
    key = @user.generate_validkey
		assert_not_equal nil, key
		assert_not_equal @user.generate_validkey, key
  end
  
  def test_valid_name
		assert_match /^[A-Za-z0-9\-\s]*$/, @user["firstname"]
		assert_match /^[A-Za-z0-9\-\s]*$/, @user["lastname"]
		assert @user.save, "your fixture is wrecked, name Jane Doe!"
		@user[:firstname] = "a" * 41
		assert !@user.save
		@user[:firstname] = "jane"
		assert @user.save
		@user[:lastname] = "a" * 41
		assert !@user.save 
  end

  def test_valid_confirmed
		@user[:confirmed] = nil
		assert !@user.save, "confirmed is nil!"
		@user[:confirmed] = "foo"
		assert !@user.save, "confirmed is not a number!"

		# XXX shouldn't this fail?
		@user[:confirmed] = -1
##		assert !@user.save, "confirmed is negative!"

	  @user[:confirmed] = 0
		assert @user.save
		@user[:confirmed] = 1
		assert @user.save
  end

  # ensures our users fit the database
  def test_CRUD
    # Create a user
    joe = User.new({
						:login => 'mylogin', 
						:firstname => 'first', 
						:lastname => 'last', 
						:email => 'login@example.com'
					})
    # the model protects IP addr, so we must set it here
    joe[:ipaddr] = '12.23.34.45'
		joe[:confirmed] = 0

    # save him
		assert !joe.save, "shouldn t be saved, no password"
		joe.password = "joejoe"

    # save him
		assert joe.save, "joe is saved because he's a good Xan"
		assert_equal joe.cryptpassword, 'c16fbe5548b1cf4aaed8fdee5b5faecd546fbd48', 'password don t match'

    # read him back
    user_from_db = User.find(joe.id)

		assert user_from_db.domains.include?('USERS') 

    # compare 
    assert_equal joe[:login], user_from_db[:login], "logins should be equal"

    # change password
    user_from_db[:password] = "newpass"

    # save new password
		assert user_from_db.save, "user should be saved"

    # assert password changed
    updated_user = User.find(joe.id)
		#assert_not_equal updated_user[:cryptpassword],
		#  UserPasswordCryptSHA.crypt(joe[:login],joe[:password]), 
		#	"password should have been changed"

    # destroy it
    assert user_from_db.destroy, "user should be destroyed"
    !assert updated_user.destroy, "user should already be destroyed"
  end

  def test_credentials
		@user.domains = {}
    assert @user.acl?(nil)
    assert @user.acl?('')
		assert !@user.acl?(1)
		assert !@user.acl?(234)
		@user.domains = User.str2domain('USERS')
		assert_equal @user.domains['USERS'], 1
		assert @user.acl?('USERS')
		assert @user.acl?('USERS,1')
		assert !@user.acl?('USERS,0')
		assert @user.acl?('CUSTOMERS,0')
		@user.domains = User.str2domain('USERS ADMIN PROJECT_DOOM,3 234')
		assert @user.acl?('USERS ADMIN PROJECT_DOOM,3')
    assert @user.acl?('USERS ADMIN PROJECT_DOOM,3 CUSTOMERS,0')		
    assert !@user.acl?('USERS,0 ADMIN PROJECT_DOOM,3 CUSTOMERS,0')		
		assert @user.acl?('USERS,1')
		assert !@user.acl?('USERS,2')
		assert @user.acl?('PROJECT_DOOM')
		assert @user.acl?('PROJECT_DOOM,1')
		assert @user.acl?('PROJECT_DOOM,3')
		assert !@user.acl?('PROJECT_DOOM ADMIN,0')
		assert @user.acl?('CUSTOMER,0')
    assert @user.acl?(234)
    assert @user.acl?('234')
    assert !@user.acl?('USERS,SUCK')
  end

end
