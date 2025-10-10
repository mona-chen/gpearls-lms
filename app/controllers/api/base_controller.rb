class Api::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    # Use Devise's JWT authentication
    authenticate_user_from_token!
  end

  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { message: 'Missing token' }, status: :unauthorized unless token

    begin
      # Decode the JWT token manually to get user
      decoded_token = JWT.decode(token, ENV.fetch('DEVISE_JWT_SECRET_KEY', 'your-secret-key'), true, algorithm: 'HS256')
      user_id = decoded_token.first['sub']
      @current_user = User.find(user_id)

      # Check if token is in denylist (revoked)
      if JwtDenylist.exists?(jti: decoded_token.first['jti'])
        return render json: { message: 'Token revoked' }, status: :unauthorized
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { message: 'Invalid token' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end