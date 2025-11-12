class DashboardController < ActionController::Base
  include ActionController::Cookies
  include Devise::Controllers::Helpers

  before_action :authenticate_user!

  def index
    @onboarding_status = Onboarding::OnboardingService.call(user: current_user)
  end

  private

  def authenticate_user!
    unless current_user
      render json: { error: "Not Authorized" }, status: :unauthorized
    end
  end

  def current_user
    return @current_user if defined?(@current_user)

    # Try session authentication first
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
      if @current_user.present?
        Current.user = @current_user
        return @current_user
      end
    end

    # Try cookie authentication (Frappe style)
    if cookies[:sid] && cookies[:user_id]
      email = CGI.unescape(cookies[:user_id])
      @current_user = User.find_by(email: email)
      if @current_user.present?
        Current.user = @current_user
        return @current_user
      end
    end

    @current_user = nil
  end
end
