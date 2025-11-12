module AuthHelpers
  def generate_jwt_token(user)
    Warden::JWTAuth::TokenEncoder.new.call({ sub: user.id })
  end

  def auth_headers(user)
    token = generate_jwt_token(user)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end

  def json_response
    JSON.parse(response.body)
  end

  def sign_in_user(user)
    post '/api/login', params: {
      email: user.email,
      password: user.password
    }, as: :json
  end
end
