class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Devise::Controllers::Helpers
  
  protected
  
  def authenticate_user!
    if user_signed_in?
      @current_user = current_user
    else
      render json: { error: 'Not Authorized' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user ||= warden.authenticate(scope: :user)
  end
  
  def user_signed_in?
    !!current_user
  end
  
  def warden
    request.env['warden']
  end
end
