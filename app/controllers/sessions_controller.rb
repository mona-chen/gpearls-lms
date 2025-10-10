class SessionsController < ActionController::Base
  protect_from_forgery with: :exception, except: [:create, :destroy]

  require 'jwt'

  def new
    # Render the proper login page template
    render :new
  end

  def signup
    # Render the signup page template
    render :signup
  end

  def create
    user = User.find_by(email: params[:usr])

    if user && user.valid_password?(params[:pwd])
      # Generate JWT token for frontend compatibility
      jti = SecureRandom.uuid
      user.update!(jti: jti)  # Store JTI in user record
      payload = {
        sub: user.id,
        iat: Time.now.to_i,
        exp: 1.day.from_now.to_i,
        jti: jti
      }
      token = JWT.encode(payload, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), 'HS256')

      # Set cookie for session-based auth (Frappe style)
      cookies.signed[:user_id] = user.full_name

      render json: {
        message: 'Logged In',
        token: token,
        full_name: user.full_name,
        user_type: user.user_type,
        user: user.id,
        home_page: '/lms'
      }
    else
      render json: { message: 'Invalid login credentials' }, status: :unauthorized
    end
  end
  
  def destroy
    sign_out(current_user) if current_user
    cookies.delete :user_id
    render json: { message: 'Logged Out' }
  end
end