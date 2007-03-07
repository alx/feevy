class Notification < ActionMailer::Base
  def forgot(user, app, sent_on = Time.now)
    @recipients = "#{user.login} <#{user.email}>"
    @from       = "#{app['title']} Admin <#{app['email']}>"
    @subject    = 'Password Reminder'
    @body       = {'user' => user, 'app' => app}
    @sent_on    = sent_on
  end

  def signup(user, app, sent_on = Time.now)
		@recipients = "#{user.login} <#{user.email}>"
		@from       = "#{app['title']} Admin <#{app['email']}>"
		@subject    = 'You requested for an account'
		@body       = {'user' => user, 'app' => app}
		@sent_on    = sent_on
  end
  
  def emailchange (user, app, sent_on = Time.now)
     @recipients = "#{user.login} <#{user.email}>"
     @from       = "#{app['title']} Admin <#{app['email']}>"
     @subject    = 'Email change'
     @body       = {'user' => user, 'app' => app}
     @sent_on    = sent_on
  end

	def admin_newuser (user, password, app, sent_on = Time.now)
     @recipients = "#{user.login} <#{user.email}>"
     @from       = "#{app['title']} Admin <#{app['email']}>"
     @subject    = 'New account'
     @body       = {'user' => user, 'password' => password, 'app' => app}
     @sent_on    = sent_on
	end
end
