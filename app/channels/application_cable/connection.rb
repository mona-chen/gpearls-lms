module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token] || request.headers['Authorization']&.split(' ')&.last
      return reject_unauthorized_connection unless token

      begin
        decoded = JWT.decode(token, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), true, { algorithm: 'HS256' })
        payload = decoded[0]
        user = User.find_by(id: payload['sub'], jti: payload['jti'])

        if user && payload['exp'] > Time.now.to_i
          user
        else
          reject_unauthorized_connection
        end
      rescue JWT::DecodeError, JWT::ExpiredSignature
        reject_unauthorized_connection
      end
    end
  end
end
