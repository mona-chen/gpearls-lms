require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  let(:instructor) { build(:user, :instructor) }
  let(:moderator) { build(:user, :moderator) }
  let(:evaluator) { build(:user, :evaluator) }

  describe 'FactoryBot factories' do
    it 'has a valid default factory' do
      expect(user).to be_valid
    end

    it 'creates valid instructor factory' do
      expect(instructor).to be_valid
      expect(instructor.is_instructor).to be true
      expect(instructor.is_student).to be false
    end

    it 'creates valid moderator factory' do
      expect(moderator).to be_valid
      expect(moderator.is_moderator).to be true
      expect(moderator.is_student).to be false
    end

    it 'creates valid evaluator factory' do
      expect(evaluator).to be_valid
      expect(evaluator.is_evaluator).to be true
      expect(evaluator.is_student).to be false
    end
  end

  describe 'Devise modules' do
    it 'includes database_authenticatable' do
      expect(user).to respond_to(:valid_password?)
    end

    it 'includes registerable' do
      expect(user).to respond_to(:email_changed?)
    end

    it 'includes recoverable' do
      expect(user).to respond_to(:reset_password_token)
    end

    it 'includes rememberable' do
      expect(user).to respond_to(:remember_expires_at)
    end

    it 'includes validatable' do
      expect(user).to respond_to(:email)
    end

    it 'includes trackable' do
      expect(user).to respond_to(:sign_in_count)
      expect(user).to respond_to(:current_sign_in_at)
      expect(user).to respond_to(:last_sign_in_at)
      expect(user).to respond_to(:current_sign_in_ip)
      expect(user).to respond_to(:last_sign_in_ip)
    end

    it 'includes timeoutable' do
      expect(user).to respond_to(:timeout_in)
    end
  end

  describe 'Associations' do
    it 'has many enrollments' do
      expect(user).to have_many(:enrollments)
    end

    it 'has many batch_enrollments' do
      expect(user).to have_many(:batch_enrollments)
    end

    it 'has many courses through enrollments' do
      expect(user).to have_many(:courses).through(:enrollments)
    end

    it 'has many batches through batch_enrollments' do
      expect(user).to have_many(:batches).through(:batch_enrollments)
    end

    it 'has many lesson_progress' do
      expect(user).to have_many(:lesson_progress)
    end
  end

  describe 'Validations' do
    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'is not valid without email' do
      user.email = nil
      expect(user).not_to be_valid
    end

    it 'is not valid with invalid email format' do
      user.email = 'invalid_email'
      expect(user).not_to be_valid
    end

    it 'is not valid with duplicate email' do
      user.save!
      duplicate_user = build(:user, email: user.email)
      expect(duplicate_user).not_to be_valid
    end

    it 'is not valid without password' do
      user.password = nil
      expect(user).not_to be_valid
    end

    it 'is not valid with short password' do
      user.password = '123'
      expect(user).not_to be_valid
    end
  end

  describe 'Role methods' do
    describe '#instructor?' do
      it 'returns true for instructor users' do
        expect(instructor.instructor?).to be true
      end

      it 'returns false for non-instructor users' do
        expect(user.instructor?).to be false
      end
    end

    describe '#moderator?' do
      it 'returns true for moderator users' do
        expect(moderator.moderator?).to be true
      end

      it 'returns false for non-moderator users' do
        expect(user.moderator?).to be false
      end
    end

    describe '#evaluator?' do
      it 'returns true for evaluator users' do
        expect(evaluator.evaluator?).to be true
      end

      it 'returns false for non-evaluator users' do
        expect(user.evaluator?).to be false
      end
    end

    describe '#student?' do
      it 'returns true for student users' do
        expect(user.student?).to be true
      end

      it 'returns false for non-student users' do
        expect(instructor.student?).to be false
      end
    end
  end

  describe '#roles' do
    it 'returns LMS Student role for regular users' do
      expect(user.roles).to include('LMS Student')
    end

    it 'returns Course Creator role for instructors' do
      expect(instructor.roles).to include('Course Creator')
    end

    it 'returns Moderator role for moderators' do
      expect(moderator.roles).to include('Moderator')
    end

    it 'returns Batch Evaluator role for evaluators' do
      expect(evaluator.roles).to include('Batch Evaluator')
    end

    it 'returns single role for users' do
      instructor = create(:user, :instructor)
      expect(instructor.roles).to eq([ 'Course Creator' ])
    end
  end

  describe '#first_name' do
    it 'returns first part of full_name' do
      user.full_name = 'John Doe'
      expect(user.first_name).to eq('John')
    end

    it 'returns User when full_name is nil' do
      user.full_name = nil
      expect(user.first_name).to eq('User')
    end

    it 'handles single name' do
      user.full_name = 'John'
      expect(user.first_name).to eq('John')
    end

    it 'handles multiple word names' do
      user.full_name = 'John Michael Doe'
      expect(user.first_name).to eq('John')
    end
  end

  describe '#last_name' do
    it 'returns last part of full_name' do
      user.full_name = 'John Doe'
      expect(user.last_name).to eq('Doe')
    end

    it 'returns empty string when full_name is nil' do
      user.full_name = nil
      expect(user.last_name).to eq('')
    end

    it 'handles single name' do
      user.full_name = 'John'
      expect(user.last_name).to eq('John')
    end

    it 'handles multiple word names' do
      user.full_name = 'John Michael Doe'
      expect(user.last_name).to eq('Doe')
    end
  end

  describe '#session_user' do
    it 'returns user session data hash' do
      user.save!
      session_data = user.session_user

      expect(session_data).to be_a(Hash)
      expect(session_data[:name]).to eq(user.id)
      expect(session_data[:username]).to eq(user.username)
      expect(session_data[:full_name]).to eq(user.full_name)
      expect(session_data[:email]).to eq(user.email)
      expect(session_data[:user_image]).to eq(user.user_image)
      expect(session_data[:is_moderator]).to eq(user.is_moderator)
      expect(session_data[:is_instructor]).to eq(user.is_instructor)
      expect(session_data[:is_evaluator]).to eq(user.is_evaluator)
      expect(session_data[:is_student]).to eq(user.is_student)
      expect(session_data[:user_type]).to eq(user.user_type)
      expect(session_data[:roles]).to eq(user.roles)
    end

    it 'includes correct role information' do
      instructor.save!
      session_data = instructor.session_user

      expect(session_data[:is_instructor]).to be true
      expect(session_data[:roles]).to include('Course Creator')
    end
  end

  describe 'Scopes and queries' do
    describe 'finding users by role' do
      it 'can find instructors' do
        instructor.save!
        user.save!

        instructors = User.where(role: "Course Creator")
        expect(instructors).to include(instructor)
        expect(instructors).not_to include(user)
      end

      it 'can find moderators' do
        moderator.save!
        user.save!

        moderators = User.where(role: "Moderator")
        expect(moderators).to include(moderator)
        expect(moderators).not_to include(user)
      end

      it 'can find evaluators' do
        evaluator.save!
        user.save!

        evaluators = User.where(role: "Batch Evaluator")
        expect(evaluators).to include(evaluator)
        expect(evaluators).not_to include(user)
      end
    end
  end

  describe 'Callbacks and hooks' do
    it 'can be created with valid attributes' do
      expect {
        create(:user)
      }.to change(User, :count).by(1)
    end

    it 'can be updated' do
      user.save!
      expect {
        user.update!(full_name: 'Updated Name')
      }.to change(user, :full_name).to('Updated Name')
    end

    it 'can be destroyed' do
      user.save!
      expect {
        user.destroy
      }.to change(User, :count).by(-1)
    end
  end

  describe 'Edge cases' do
    it 'handles user with student role' do
      user.role = "LMS Student"

      expect(user.student?).to be true
      expect(user.instructor?).to be false
      expect(user.moderator?).to be false
      expect(user.evaluator?).to be false
    end

    it 'handles user with instructor role' do
      user.role = "Course Creator"

      expect(user.student?).to be false
      expect(user.instructor?).to be true
      expect(user.moderator?).to be false
      expect(user.evaluator?).to be false
    end

    it 'handles empty full_name in session_user' do
      user.full_name = ''
      user.save!

      session_data = user.session_user
      expect(session_data[:full_name]).to eq('')
    end

    it 'handles nil full_name in session_user' do
      user.full_name = nil
      user.save!

      session_data = user.session_user
      expect(session_data[:full_name]).to eq(nil)
    end
  end

  describe 'JWT Authentication' do
    it 'has JWT token field' do
      expect(user).to respond_to(:jti)
    end

    it 'has JWT token field' do
      expect(user).to respond_to(:jti)
    end
  end
end
