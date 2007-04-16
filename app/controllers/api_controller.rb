class ApiController < ApplicationController
  
  def view_key
    require_auth
    unless @api_key = @user.api_key
      @api_key = @user.generate_api_key
    end
  end
end
