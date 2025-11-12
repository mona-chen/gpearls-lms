require 'rails_helper'

RSpec.describe Programs::ProgramDetailsService, type: :service do
  let(:user) { create(:user) }
  let(:program) { create(:lms_program, published: true) }
  let(:course1) { create(:course) }
  let(:course2) { create(:course) }

  before do
    create(:lms_program_course, lms_program: program, course: course1, position: 1)
    create(:lms_program_course, lms_program: program, course: course2, position: 2)
  end

  describe '.call' do
    context 'with valid program' do
      it 'returns program details with courses' do
        result = described_class.call(program.name, user)

        expect(result).to be_a(Hash)
        expect(result[:name]).to eq(program.name)
        expect(result[:title]).to eq(program.title)
        expect(result[:description]).to eq(program.description)
        expect(result[:published]).to eq(program.published)
        expect(result[:course_count]).to eq(2)
      end

      it 'includes courses in correct order' do
        result = described_class.call(program.name, user)

        courses = result[:courses]
        expect(courses.length).to eq(2)
        expect(courses[0][:title]).to eq(course1.title)
        expect(courses[0][:position]).to eq(1)
        expect(courses[1][:title]).to eq(course2.title)
        expect(courses[1][:position]).to eq(2)
      end

      it 'includes course details' do
        result = described_class.call(program.name, user)

        course_data = result[:courses].first
        expect(course_data).to have_key(:name)
        expect(course_data).to have_key(:title)
        expect(course_data).to have_key(:description)
        expect(course_data).to have_key(:position)
        expect(course_data).to have_key(:creation)
        expect(course_data).to have_key(:modified)
      end
    end

    context 'with user membership' do
      let!(:membership) { create(:lms_program_member, lms_program: program, user: user, progress: 75.5) }

      it 'includes membership information when user is enrolled' do
        result = described_class.call(program.name, user)

        expect(result).to have_key(:membership)
        expect(result).to have_key(:progress)
        expect(result[:progress]).to eq(75.5)

        membership_data = result[:membership]
        expect(membership_data[:member]).to eq(user.id)
        expect(membership_data[:progress]).to eq(75.5)
        expect(membership_data[:completed]).to be_falsey
      end
    end

    context 'without user membership' do
      it 'includes zero progress when user is not enrolled' do
        result = described_class.call(program.name, user)

        expect(result[:progress]).to eq(0.0)
        expect(result[:membership]).to be_nil
      end
    end

    context 'with invalid program' do
      it 'returns nil for non-existent program' do
        result = described_class.call('non-existent-program', user)

        expect(result).to be_nil
      end
    end

    context 'Frappe API compatibility' do
      it 'returns exact field structure matching Frappe LMS' do
        result = described_class.call(program.name, user)

        expected_fields = [
          :name, :title, :description, :published, :featured,
          :course_count, :member_count, :courses, :creation, :modified, :owner
        ]

        expected_fields.each do |field|
          expect(result).to have_key(field), "Missing field: #{field}"
        end

        # Check courses structure
        course_data = result[:courses].first
        expected_course_fields = [ :name, :title, :description, :position, :creation, :modified ]
        expected_course_fields.each do |field|
          expect(course_data).to have_key(field), "Missing course field: #{field}"
        end
      end

      it 'formats dates correctly' do
        result = described_class.call(program.name, user)

        expect(result[:creation]).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(result[:modified]).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)

        course_data = result[:courses].first
        expect(course_data[:creation]).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(course_data[:modified]).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end
    end
  end
end
