class Api::AuthenticationController < ApplicationController
  
  def login
    user = User.find_by(email: params[:usr])

    if user&.valid_password?(params[:pwd])
      # Generate JWT token with proper Devise JWT format
      jti = SecureRandom.uuid
      user.update!(jti: jti)
      payload = { sub: user.id, jti: jti, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), 'HS256')
      
      render json: {
        message: 'Logged In',
        full_name: user.full_name,
        user_type: user.user_type,
        user: user.id,
        token: token,
        home_page: '/lms'
      }
    else
      render json: { message: 'Invalid login credentials' }, status: :unauthorized
    end
  end

  def signup
    # Validate required parameters
    return render json: { message: 'Email and full name are required' }, status: :bad_request unless params[:signup_email].present? && params[:full_name].present?

    # Check if user already exists
    existing_user = User.find_by(email: params[:signup_email])
    if existing_user
      if existing_user.enabled?
        return render json: { message: 'Already Registered' }, status: :unprocessable_entity
      else
        return render json: { message: 'Registered but disabled' }, status: :unprocessable_entity
      end
    end

    # Rate limiting check (similar to Frappe's approach)
    recent_users = User.where(created_at: 1.hour.ago..Time.current).count
    if recent_users > 300
      return render json: { message: 'Too many users signed up recently, please try back in an hour' }, status: :too_many_requests
    end

    begin
      # Create new user
      user = User.new(
        email: params[:signup_email],
        full_name: params[:full_name],
        password: params[:password],
        password_confirmation: params[:password],
        user_type: 'LMS Student',
        enabled: true
      )

      # Set additional fields if provided
      user.user_category = params[:user_category] if params[:user_category].present?

      user.save!

      # Add LMS Student role
      user.add_role(:lms_student) if user.respond_to?(:add_role)

      render json: {
        message: 'Your Account has been successfully created! Please check your email for verification.',
        user_id: user.id
      }
    rescue => e
      Rails.logger.error "Signup error: #{e.message}"
      render json: { message: "Failed to create account: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def logout
    sign_out(current_user) if current_user
    cookies.delete :user_id
    current_user&.update(jti: nil)
    render json: { message: 'Logged Out' }
  end
end