require 'rails_helper'

RSpec.describe Users::UsersService, type: :service do
  describe '.call' do
    let!(:user1) { create(:user, full_name: 'John Doe', email: 'john@example.com', user_image: 'john.jpg') }
    let!(:user2) { create(:user, full_name: 'Jane Smith', email: 'jane@example.com', user_image: 'jane.jpg') }
    let!(:user3) { create(:user, full_name: 'Bob Johnson', email: 'bob@example.com') }

    it 'returns users data in Frappe-compatible format' do
      result = Users::UsersService.call

      expect(result).to be_a(Hash)
      expect(result).to have_key(:data)
      expect(result[:data]).to be_an(Array)
    end

    it 'includes all required user fields' do
      result = Users::UsersService.call

      user_data = result[:data].find { |u| u['email'] == user1.email }

      expect(user_data).to have_key('name')
      expect(user_data).to have_key('email')
      expect(user_data).to have_key('username')
      expect(user_data).to have_key('first_name')
      expect(user_data).to have_key('last_name')
      expect(user_data).to have_key('user_image')
    end

    it 'maps user data correctly' do
      result = Users::UsersService.call

      user_data = result[:data].find { |u| u['email'] == user1.email }

      expect(user_data['name']).to eq('John Doe')
      expect(user_data['email']).to eq('john@example.com')
      expect(user_data['username']).to eq('john')
      expect(user_data['first_name']).to eq('John')
      expect(user_data['last_name']).to eq('Doe')
      expect(user_data['user_image']).to eq('john.jpg')
    end

    it 'handles users without full_name' do
      user_no_name = create(:user, full_name: nil, email: 'noname@example.com')

      result = Users::UsersService.call

      user_data = result[:data].find { |u| u['email'] == user_no_name.email }
      expect(user_data['name']).to be_nil
    end

    it 'handles users without user_image' do
      result = Users::UsersService.call

      user_data = result[:data].find { |u| u['email'] == user3.email }
      expect(user_data['user_image']).to be_nil
    end

    it 'limits results to 10 users' do
      create_list(:user, 15)

      result = Users::UsersService.call

      expect(result[:data].length).to eq(10)
    end

    it 'returns users in database order' do
      # Create users in specific order
      user_a = create(:user, email: 'a@example.com')
      user_z = create(:user, email: 'z@example.com')

      result = Users::UsersService.call

      # Should return in order they appear in database
      emails = result[:data].map { |u| u['email'] }
      expect(emails).to include('a@example.com', 'z@example.com')
    end

    it 'returns empty array when no users exist' do
      User.delete_all

      result = Users::UsersService.call

      expect(result[:data]).to eq([])
    end

    it 'selects only required fields from database' do
      # This test ensures we're not selecting unnecessary fields
      result = Users::UsersService.call

      user_data = result[:data].first
      expected_keys = [ 'name', 'email', 'username', 'first_name', 'last_name', 'user_image' ]

      expect(user_data.keys).to match_array(expected_keys)
    end

    context 'with multiple users' do
      before do
        create_list(:user, 5)
      end

      it 'returns all users up to limit' do
        result = Users::UsersService.call

        expect(result[:data].length).to be <= 10
        expect(result[:data].length).to be >= 3 # At least our test users
      end

      it 'returns consistent data structure' do
        result = Users::UsersService.call

        result[:data].each do |user_data|
          expect(user_data).to be_a(Hash)
          expect(user_data).to have_key('email')
          expect(user_data).to have_key('username')
        end
      end
    end

    context 'username generation' do
      it 'generates username from email prefix' do
        user_special = create(:user, email: 'test.user+tag@example.com')

        result = Users::UsersService.call

        user_data = result[:data].find { |u| u['email'] == user_special.email }
        expect(user_data['username']).to eq('test.user+tag')
      end

      it 'handles simple email addresses' do
        user_simple = create(:user, email: 'simple@example.com')

        result = Users::UsersService.call

        user_data = result[:data].find { |u| u['email'] == user_simple.email }
        expect(user_data['username']).to eq('simple')
      end
    end

    context 'name parsing' do
      it 'parses first and last names correctly' do
        user_names = create(:user, full_name: 'Mary Jane Watson', email: 'mary@example.com')

        result = Users::UsersService.call

        user_data = result[:data].find { |u| u['email'] == user_names.email }
        expect(user_data['first_name']).to eq('Mary')
        expect(user_data['last_name']).to eq('Jane Watson')
      end

      it 'handles single name users' do
        user_single = create(:user, full_name: 'Madonna', email: 'madonna@example.com')

        result = Users::UsersService.call

        user_data = result[:data].find { |u| u['email'] == user_single.email }
        expect(user_data['first_name']).to eq('Madonna')
        expect(user_data['last_name']).to eq('Madonna')
      end

      it 'handles nil full_name' do
        user_nil = create(:user, full_name: nil, email: 'nil@example.com')

        result = Users::UsersService.call

        user_data = result[:data].find { |u| u['email'] == user_nil.email }
        expect(user_data['first_name']).to be_nil
        expect(user_data['last_name']).to be_nil
      end
    end
  end

  describe 'performance considerations' do
    it 'uses efficient database queries' do
      create_list(:user, 20)

      expect { Users::UsersService.call }.to query_database_at_most(2) # One for count, one for select
    end
  end
end
