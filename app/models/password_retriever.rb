class PasswordRetriever < ActionMailer::Base
  def forgot_password( user )
    # Email header info MUST be added here
    @recipients = user.email
    @from = "admin@feevy.com"
    @subject = "[Feevy] Forgot your password?"

    # Email body substitutions go here
    #@body[“first_name”] = user.first_name
    #@body[“last_name”] = user.last_name
    @body["reset_url"] = "http://" << "www.feevy.com" << "/user/reset_password/" << user.id
  end
end
