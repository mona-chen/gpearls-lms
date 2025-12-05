class Api::AuthenticationController < ApplicationController
  def login
    # Handle CORS preflight requests
    if request.method == "OPTIONS"
      response.headers["Access-Control-Allow-Origin"] = request.origin || "*"
      response.headers["Access-Control-Allow-Credentials"] = "true"
      response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, X-Frappe-CSRF-Token, X-Frappe-CMD, X-Requested-With"
      head :ok
      return
    end

    user = User.find_by(email: params[:usr])

    if user&.valid_password?(params[:pwd]) && user.enabled
      # Store user in session (Frappe-style session management)
      session[:user_id] = user.id

      # Generate JWT token for API authentication
      payload = {
        sub: user.id,
        jti: SecureRandom.uuid,
        exp: 1.day.from_now.to_i,
        iat: Time.current.to_i
      }
      token = JWT.encode(payload, ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base), "HS256")

      # Update JTI for token invalidation
      user.update(jti: payload[:jti])

      # Set Frappe-compatible cookies with proper path and security
      cookie_options = {
        expires: 7.days.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        path: "/"
      }

      cookies[:sid] = { value: SecureRandom.hex(16), **cookie_options }
      cookies[:system_user] = { value: "yes", **cookie_options.except(:httponly) }
      cookies[:full_name] = { value: user.full_name, **cookie_options.except(:httponly) }
      cookies[:user_id] = { value: user.email, **cookie_options.except(:httponly) }
      cookies[:user_image] = { value: user.profile_image || "", **cookie_options.except(:httponly) }

      # Set CORS headers for API compatibility
      response.headers["Access-Control-Allow-Origin"] = request.origin || "*"
      response.headers["Access-Control-Allow-Credentials"] = "true"
      response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, X-Frappe-CSRF-Token, X-Frappe-CMD, X-Requested-With"

      # Return Frappe-compatible user format with JWT token
      user_data = {
        name: user.full_name,
        email: user.email,
        username: user.email.split("@").first,
        first_name: user.first_name,
        last_name: user.last_name,
        user_image: user.profile_image,
        enabled: user.enabled,
        user_type: user.user_type || "LMS Student",
        roles: [ user.user_type || "LMS Student" ],
        is_instructor: user.user_type == "Course Creator",
        is_moderator: user.user_type == "Moderator",
        is_evaluator: user.user_type == "Batch Evaluator",
        is_student: user.user_type != "Course Creator" && user.user_type != "Moderator" && user.user_type != "Batch Evaluator"
      }

      response_data = {
        message: "Logged In",
        user: user_data,
        home_page: "/lms",
        token: token
      }

      render json: response_data
    else
      render json: { message: "Invalid login credentials" }, status: :unauthorized
    end
  end

  def signup
    # Handle CORS preflight requests
    if request.method == "OPTIONS"
      response.headers["Access-Control-Allow-Origin"] = request.origin || "*"
      response.headers["Access-Control-Allow-Credentials"] = "true"
      response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, X-Frappe-CSRF-Token, X-Frappe-CMD, X-Requested-With"
      head :ok
      return
    end

    # Validate required parameters
    return render json: { message: "Email and full name are required" }, status: :bad_request unless params[:signup_email].present? && params[:full_name].present?

    # Check if user already exists
    existing_user = User.find_by(email: params[:signup_email])
    if existing_user
      if existing_user.enabled
        return render json: { message: "Already Registered" }, status: :unprocessable_entity
      else
        return render json: { message: "Registered but disabled" }, status: :unprocessable_entity
      end
    end

    # Rate limiting check (similar to Frappe's approach)
    recent_users = User.where(created_at: 1.hour.ago..Time.current).count
    if recent_users > 300
      return render json: { message: "Too many users signed up recently, please try back in an hour" }, status: :too_many_requests
    end

    begin
      # Create new user
      user = User.new(
        email: params[:signup_email],
        full_name: params[:full_name],
        password: params[:password],
        password_confirmation: params[:password],
        role: "LMS Student",
        status: "Active"
      )

      # Split full name into first and last name
      if params[:full_name].present?
        name_parts = params[:full_name].strip.split(" ", 2)
        user.first_name = name_parts[0] if name_parts[0]
        user.last_name = name_parts[1] if name_parts[1]
      end

      # Generate username from email
      user.username = params[:signup_email].split("@").first

      # Set additional fields if provided
      user.user_category = params[:user_category] if params[:user_category].present?

      user.save!

      # Add LMS Student role
      user.add_role(:lms_student) if user.respond_to?(:add_role)

      render json: {
        message: "Your Account has been successfully created! Please check your email for verification.",
        user_id: user.id
      }
    rescue => e
      Rails.logger.error "Signup error: #{e.message}"
      render json: { message: "Failed to create account: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def logout
    # Get current user from session if available
    if session[:user_id]
      user = User.find_by(id: session[:user_id])
      user&.update(jti: nil)
    end

    # Clear all Frappe-style cookies by setting them to expired
    expired_options = { value: "", expires: 1.year.ago, path: "/" }
    cookies[:sid] = expired_options
    cookies[:system_user] = expired_options
    cookies[:full_name] = expired_options
    cookies[:user_id] = expired_options
    cookies[:user_image] = expired_options

    # Clear Rails session
    reset_session

    render json: { message: "Logged Out" }
  end

  def options
    # Handle CORS preflight requests
    response.headers["Access-Control-Allow-Origin"] = request.origin || "*"
    response.headers["Access-Control-Allow-Credentials"] = "true"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, X-Frappe-CSRF-Token, X-Frappe-CMD, X-Requested-With"

    head :ok
  end
end
