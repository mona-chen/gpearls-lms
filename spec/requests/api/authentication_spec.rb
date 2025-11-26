require 'rails_helper'

RSpec.describe 'API::Authentication', type: :request do
  let(:user) { create(:user, email: 'test@example.com', full_name: 'Test User', profile_image: nil) }
  let(:instructor) { create(:user, :instructor, email: 'instructor@example.com') }
  let(:moderator) { create(:user, :moderator, email: 'moderator@example.com') }
  let(:evaluator) { create(:user, :evaluator, email: 'evaluator@example.com') }

  describe 'POST /api/login' do
    context 'with valid credentials' do
      it 'logs in successfully and returns Frappe-compatible response' do
        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Logged In')
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('user')
        expect(json_response['home_page']).to eq('/lms')
      end

      it 'returns correct user data structure' do
        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        json_response = JSON.parse(response.body)
        user_data = json_response['user']

        expect(user_data['name']).to eq('Test User')
        expect(user_data['email']).to eq('test@example.com')
        expect(user_data['username']).to eq('test')
        expect(user_data['first_name']).to eq('Test')
        expect(user_data['last_name']).to eq('User')
        expect(user_data['enabled']).to be true
        expect(user_data['user_type']).to eq('LMS Student')
        expect(user_data['roles']).to include('LMS Student')
        expect(user_data['is_student']).to be true
      end

      it 'sets proper cookies for Frappe compatibility' do
        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        expect(cookies['sid']).to be_present
        expect(cookies['system_user']).to eq('yes')
        expect(cookies['full_name']).to eq('Test User')
        expect(cookies['user_id']).to eq('test@example.com')
        expect(cookies['user_image']).to eq('')
      end

      it 'sets CORS headers for Frappe compatibility' do
        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        expect(response.headers['Access-Control-Allow-Origin']).to be_present
        expect(response.headers['Access-Control-Allow-Credentials']).to eq('true')
        expect(response.headers['Access-Control-Allow-Methods']).to eq('GET, POST, OPTIONS')
      end

      it 'returns instructor-specific data for instructor users' do
        post '/api/login', params: { usr: instructor.email, pwd: 'Password123!' }

        json_response = JSON.parse(response.body)
        user_data = json_response['user']

        expect(user_data['user_type']).to eq('Course Creator')
        expect(user_data['roles']).to include('Course Creator')
        expect(user_data['is_instructor']).to be true
        expect(user_data['is_student']).to be false
      end

      it 'returns moderator-specific data for moderator users' do
        post '/api/login', params: { usr: moderator.email, pwd: 'Password123!' }

        json_response = JSON.parse(response.body)
        user_data = json_response['user']

        expect(user_data['user_type']).to eq('Moderator')
        expect(user_data['roles']).to include('Moderator')
        expect(user_data['is_moderator']).to be true
        expect(user_data['is_student']).to be false
      end

      it 'returns evaluator-specific data for evaluator users' do
        post '/api/login', params: { usr: evaluator.email, pwd: 'Password123!' }

        json_response = JSON.parse(response.body)
        user_data = json_response['user']

        expect(user_data['user_type']).to eq('Batch Evaluator')
        expect(user_data['roles']).to include('Batch Evaluator')
        expect(user_data['is_evaluator']).to be true
        expect(user_data['is_student']).to be false
      end

      it 'updates user JTI for JWT invalidation' do
        old_jti = user.jti

        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        user.reload
        expect(user.jti).not_to eq(old_jti)
        expect(user.jti).to be_present
      end

      it 'returns valid JWT token' do
        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        json_response = JSON.parse(response.body)
        token = json_response['token']

        # Decode token to verify structure
        decoded_token = JWT.decode(token, ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.secret_key_base), true, algorithm: 'HS256')
        payload = decoded_token.first

        expect(payload['sub']).to eq(user.id)
        expect(payload).to have_key('jti')
        expect(payload).to have_key('exp')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post '/api/login', params: { usr: user.email, pwd: 'wrongpassword' }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Invalid login credentials')
      end

      it 'returns unauthorized for non-existent user' do
        post '/api/login', params: { usr: 'nonexistent@example.com', pwd: 'Password123!' }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Invalid login credentials')
      end

      it 'returns unauthorized for missing parameters' do
        post '/api/login', params: {}

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with disabled user' do
      it 'returns unauthorized for disabled user' do
        user.update!(enabled: false)

        post '/api/login', params: { usr: user.email, pwd: 'Password123!' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/signup' do
    context 'with valid parameters' do
      let(:signup_params) do
        {
          signup_email: 'newuser@example.com',
          full_name: 'New User',
          password: 'Password123!'
        }
      end

      it 'creates new user successfully' do
        expect {
          post '/api/signup', params: signup_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('successfully created')
        expect(json_response).to have_key('user_id')
      end

      it 'creates user with correct attributes' do
        post '/api/signup', params: signup_params

        new_user = User.find_by(email: 'newuser@example.com')
        expect(new_user.full_name).to eq('New User')
        expect(new_user.user_type).to eq('LMS Student')
        expect(new_user.enabled).to be true
      end

      it 'accepts optional user_category parameter' do
        post '/api/signup', params: signup_params.merge(user_category: 'Student')

        new_user = User.find_by(email: 'newuser@example.com')
        expect(new_user.user_category).to eq('Student')
      end
    end

    context 'with invalid parameters' do
      it 'returns bad request for missing email' do
        post '/api/signup', params: { full_name: 'Test User', password: 'Password123!' }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Email and full name are required')
      end

      it 'returns bad request for missing full_name' do
        post '/api/signup', params: { signup_email: 'test@example.com', password: 'Password123!' }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Email and full name are required')
      end

      it 'returns unprocessable entity for existing enabled user' do
        existing_user = create(:user, email: 'existing@example.com', enabled: true)

        post '/api/signup', params: {
          signup_email: existing_user.email,
          full_name: 'Another User',
          password: 'Password123!'
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Already Registered')
      end

      it 'returns unprocessable entity for existing disabled user' do
        existing_user = create(:user, email: 'existing@example.com', enabled: false)

        post '/api/signup', params: {
          signup_email: existing_user.email,
          full_name: 'Another User',
          password: 'Password123!'
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Registered but disabled')
      end
    end

    context 'rate limiting' do
      it 'allows normal signup rate' do
        post '/api/signup', params: {
          signup_email: 'normal@example.com',
          full_name: 'Normal User',
          password: 'Password123!'
        }

        expect(response).to have_http_status(:success)
      end

      it 'blocks excessive signups' do
        # Create many recent users to trigger rate limit
        create_list(:user, 301, created_at: 30.minutes.ago)

        post '/api/signup', params: {
          signup_email: 'excessive@example.com',
          full_name: 'Excessive User',
          password: 'Password123!'
        }

        expect(response).to have_http_status(:too_many_requests)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('Too many users signed up recently')
      end
    end

    context 'error handling' do
      it 'handles validation errors gracefully' do
        post '/api/signup', params: {
          signup_email: 'invalid-email',
          full_name: 'Test User',
          password: '123' # Too short
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to include('Failed to create account')
      end
    end
  end

  describe 'POST /api/logout' do
    before do
      # Login first to set up session
      post '/api/login', params: { usr: user.email, pwd: 'Password123!' }
    end

    it 'logs out successfully' do
      post '/api/logout'

      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Logged Out')
    end

    it 'clears Frappe-style cookies' do
      post '/api/logout'

      expect(cookies['sid']).to eq('')
      expect(cookies['system_user']).to eq('')
      expect(cookies['full_name']).to eq('')
      expect(cookies['user_id']).to eq('')
      expect(cookies['user_image']).to eq('')
    end

    it 'clears user JTI' do
      post '/api/logout'

      user.reload
      expect(user.jti).to be_nil
    end

    it 'works without authenticated user' do
      post '/api/logout'

      expect(response).to have_http_status(:success)
    end
  end

  describe 'CORS preflight requests' do
    it 'handles OPTIONS requests for login' do
      process :options, '/api/login'

      expect(response).to have_http_status(:success)
      expect(response.headers['Access-Control-Allow-Origin']).to be_present
      expect(response.headers['Access-Control-Allow-Methods']).to include('POST')
    end

    it 'handles OPTIONS requests for signup' do
      process :options, '/api/signup'

      expect(response).to have_http_status(:success)
      expect(response.headers['Access-Control-Allow-Origin']).to be_present
      expect(response.headers['Access-Control-Allow-Methods']).to include('POST')
    end
  end
end
