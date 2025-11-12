module Api
  module Compatibility
    class BaseController < ActionController::Base
      skip_before_action :verify_authenticity_token, raise: false

      protected

      def current_user
        @current_user ||= authenticate_user_from_token!
      end

      def authenticate_user_from_token!
        # JWT token authentication
        token = request.headers['Authorization']&.split(' ')&.last

        if token.present?
          begin
            decoded = JWT.decode(token, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), true, { algorithm: 'HS256' })
            payload = decoded[0]
            user = User.find_by(id: payload['sub'], jti: payload['jti'])

            if user && payload['exp'] > Time.now.to_i
              return user
            end
          rescue JWT::DecodeError, JWT::ExpiredSignature => e
            Rails.logger.info "JWT decode error: #{e.message}"
          end
        end

        # Session-based authentication
        if session[:user_id].present?
          return User.find_by(id: session[:user_id])
        end

        # Frappe-style cookie authentication
        if cookies[:user_id].present?
          email = CGI.unescape(cookies[:user_id])
          return User.find_by(email: email)
        end

        nil
      end

      def render_unauthorized(message = 'Not authenticated')
        render json: { message: message }, status: :unauthorized
      end

      def render_not_found(message = 'Not found')
        render json: { message: message }, status: :not_found
      end

      def render_success(data = nil)
        render json: { message: data || { success: true } }
      end
    end
  end
end