class Api::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    # Use session-based authentication like Frappe LMS
    authenticate_user_from_session!
  end

  def authenticate_user_from_session!
    # Try session authentication first
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
      return if @current_user
    end

    # Try cookie authentication (Frappe style)
    if cookies[:sid] && cookies[:user_id]
      email = CGI.unescape(cookies[:user_id])
      @current_user = User.find_by(email: email)
      return if @current_user
    end

    # If no authentication found, set current_user to nil
    @current_user = nil
  end

  def current_user
    @current_user
  end
end
