require 'rails_helper'

RSpec.describe Users::UserInfoService, type: :service do
  let(:user) { create(:user) }
  let(:instructor) { create(:user, :instructor) }
  let(:moderator) { create(:user, :moderator) }
  let(:evaluator) { create(:user, :evaluator) }

  describe '.call' do
    context 'with a regular student user' do
      it 'returns user information in Frappe-compatible format' do
        result = Users::UserInfoService.call(user)

        expect(result).to be_a(Hash)
        expect(result[:email]).to eq(user.email)
        expect(result[:full_name]).to eq(user.full_name || user.email)
        expect(result[:username]).to eq(user.email.split('@').first)
        expect(result[:user_image]).to eq(user.user_image || '')
        expect(result[:roles]).to include('LMS Student')
        expect(result[:enabled]).to eq(1)
        expect(result[:user_type]).to eq('LMS Student')
        expect(result[:course_progress]).to be_a(Integer)
        expect(result[:last_active]).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(result[:mobile_no]).to eq("")
        expect(result[:desk_settings]).to eq({})
        expect(result[:route_permissions]).to eq([])
        expect(result[:defaults]).to eq({})
      end

      it 'includes site information' do
        result = Users::UserInfoService.call(user)

        expect(result[:site_info]).to be_a(Hash)
        expect(result[:site_info][:name]).to eq("Frappe LMS")
        expect(result[:site_info][:country]).to eq("India")
        expect(result[:site_info][:timezone]).to eq("Asia/Kolkata")
      end
    end

    context 'with an instructor user' do
      it 'returns instructor-specific roles' do
        result = Users::UserInfoService.call(instructor)

        expect(result[:roles]).to include('LMS Student', 'Course Creator', 'Workspace Manager', 'Lesson Creator')
        expect(result[:user_type]).to eq('Course Creator')
      end
    end

    context 'with a moderator user' do
      it 'returns moderator-specific roles' do
        result = Users::UserInfoService.call(moderator)

        expect(result[:roles]).to include('LMS Student', 'Moderator', 'LMS Manager', 'Course Reviewer')
        expect(result[:user_type]).to eq('Moderator')
      end
    end

    context 'with an evaluator user' do
      it 'returns evaluator-specific roles' do
        result = Users::UserInfoService.call(evaluator)

        expect(result[:roles]).to include('LMS Student', 'Batch Evaluator', 'Quiz Reviewer')
        expect(result[:user_type]).to eq('Batch Evaluator')
      end
    end

    context 'with course enrollments' do
      let(:course) { create(:course, :with_lessons) }
      let(:enrollment) { create(:enrollment, user: user, course: course) }

      before do
        enrollment
      end

      it 'calculates course progress correctly' do
        # Create some lesson progress
        create(:lesson_progress, user: user, lesson: course.lessons.first, completed: true)

        result = Users::UserInfoService.call(user)

        expect(result[:course_progress]).to be > 0
        expect(result[:course_progress]).to be <= 100
      end

      it 'returns 0 progress for no completed lessons' do
        result = Users::UserInfoService.call(user)

        expect(result[:course_progress]).to eq(0)
      end

      it 'calculates progress correctly across multiple courses' do
        course2 = create(:course, :with_lessons)
        enrollment2 = create(:enrollment, user: user, course: course2)

        # Complete some lessons in both courses
        create(:lesson_progress, user: user, lesson: course.lessons.first, completed: true)
        create(:lesson_progress, user: user, lesson: course2.lessons.first, completed: true)

        result = Users::UserInfoService.call(user)

        expect(result[:course_progress]).to be > 0
      end
    end

    context 'edge cases' do
      it 'handles user without full_name' do
        user.update!(full_name: nil)

        result = Users::UserInfoService.call(user)

        expect(result[:full_name]).to eq(user.email)
      end

      it 'handles user without user_image' do
        user.update!(user_image: nil)

        result = Users::UserInfoService.call(user)

        expect(result[:user_image]).to eq('')
      end

      it 'handles user with enabled flag' do
        user.update!(enabled: false)

        result = Users::UserInfoService.call(user)

        expect(result[:enabled]).to eq(0)
      end

      it 'handles user with Administrator user_type' do
        user.update!(user_type: 'Administrator')

        result = Users::UserInfoService.call(user)

        expect(result[:user_type]).to eq('System Manager')
        expect(result[:roles]).to include('System Manager', 'Administrator', 'LMS Manager')
      end
    end
  end

  describe 'private methods' do
    let(:service) { Users::UserInfoService.new(user) }

    describe '#calculate_overall_course_progress' do
      it 'returns 0 for user with no enrollments' do
        # Use send to access private method
        progress = service.send(:calculate_overall_course_progress)
        expect(progress).to eq(0)
      end

      it 'calculates progress correctly for completed lessons' do
        course = create(:course, :with_lessons)
        enrollment = create(:enrollment, user: user, course: course)

        # Complete first lesson
        create(:lesson_progress, user: user, lesson: course.lessons.first, completed: true)

        progress = service.send(:calculate_overall_course_progress)
        expect(progress).to be > 0
      end

      it 'handles division by zero gracefully' do
        course = create(:course)
        enrollment = create(:enrollment, user: user, course: course)

        progress = service.send(:calculate_overall_course_progress)
        expect(progress).to eq(0)
      end
    end

    describe '#map_user_type_to_frappe' do
      it 'maps Course Creator correctly' do
        mapped = service.send(:map_user_type_to_frappe, 'Course Creator')
        expect(mapped).to eq('Course Creator')
      end

      it 'maps Moderator correctly' do
        mapped = service.send(:map_user_type_to_frappe, 'Moderator')
        expect(mapped).to eq('Moderator')
      end

      it 'maps Batch Evaluator correctly' do
        mapped = service.send(:map_user_type_to_frappe, 'Batch Evaluator')
        expect(mapped).to eq('Batch Evaluator')
      end

      it 'maps Administrator to System Manager' do
        mapped = service.send(:map_user_type_to_frappe, 'Administrator')
        expect(mapped).to eq('System Manager')
      end

      it 'defaults to LMS Student for unknown types' do
        mapped = service.send(:map_user_type_to_frappe, 'Unknown Type')
        expect(mapped).to eq('LMS Student')
      end

      it 'defaults to LMS Student for nil type' do
        mapped = service.send(:map_user_type_to_frappe, nil)
        expect(mapped).to eq('LMS Student')
      end
    end

    describe '#user_roles' do
      it 'returns base roles for student' do
        roles = service.send(:user_roles)
        expect(roles).to include('LMS Student')
      end

      it 'returns instructor roles for Course Creator' do
        user.update!(user_type: 'Course Creator')
        roles = service.send(:user_roles)

        expect(roles).to include('LMS Student', 'Course Creator', 'Workspace Manager', 'Lesson Creator')
      end

      it 'removes duplicate roles' do
        user.update!(user_type: 'Course Creator')
        roles = service.send(:user_roles)

        expect(roles).to eq(roles.uniq)
      end
    end

    describe '#site_info' do
      it 'returns consistent site information' do
        site_info = service.send(:site_info)

        expect(site_info[:name]).to eq("Frappe LMS")
        expect(site_info[:country]).to eq("India")
        expect(site_info[:timezone]).to eq("Asia/Kolkata")
      end
    end
  end
end
