class SessionsController < ActionController::Base
  protect_from_forgery with: :exception, except: [:create, :destroy]

  require 'jwt'

  # Set Frappe-compatible headers
  before_action :set_frappe_headers

  def new
    # Render the proper login page template
    render :new
  end

  def signup
    # Render the signup page template
    render :signup
  end

  def create
    # Handle both JSON and form-encoded requests
    email = params[:usr] || params[:email]
    password = params[:pwd] || params[:password]

    user = User.find_by(email: email)

    if user && user.valid_password?(password)
      # Generate session ID (Frappe style)
      session_id = SecureRandom.hex(16)

      # Store session info in database/cache (simplified for now)
      # In production, you'd want to store this in Redis or database
      session[:user_id] = user.id
      session[:session_id] = session_id

      # Set Frappe-compatible cookies with proper path and security
      cookie_options = {
        expires: 7.days.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        path: '/'
      }

      cookies[:sid] = { value: session_id, **cookie_options }
      cookies[:system_user] = { value: 'yes', **cookie_options.except(:httponly) }
      cookies[:full_name] = { value: CGI.escape(user.full_name), **cookie_options.except(:httponly) }
      cookies[:user_id] = { value: CGI.escape(user.email), **cookie_options.except(:httponly) }
      cookies[:user_image] = { value: CGI.escape(user.user_image || ''), **cookie_options.except(:httponly) }

      # Set CORS headers for Frappe compatibility
      response.headers['Access-Control-Allow-Origin'] = request.origin
      response.headers['Access-Control-Allow-Credentials'] = 'true'
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, X-Frappe-CSRF-Token, X-Frappe-CMD, X-Requested-With'

      render json: {
        message: 'Logged In',
        home_page: '/lms',
        full_name: user.full_name
      }
    else
      render json: { message: 'Invalid login credentials' }, status: :unauthorized
    end
  end

  def destroy
    sign_out(current_user) if current_user

    # Clear all Frappe-style cookies
    cookies.delete :sid
    cookies.delete :system_user
    cookies.delete :full_name
    cookies.delete :user_id
    cookies.delete :user_image

    # Clear Rails session
    reset_session

    render json: { message: 'Logged Out' }
  end

  # Handle CORS preflight requests
  def handle_options
    head :ok
  end

  private

  def set_frappe_headers
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'no-referrer-when-downgrade'

    if Rails.env.production?
      response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    end
  end
end