# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Courses::CourseDetailsService, type: :service do
  let(:instructor) { create(:user, :instructor) }
  let(:student) { create(:user) }
  let(:course) { create(:course, :published, instructor: instructor) }

  describe '.call' do
    context 'with valid course id' do
      it 'returns course details with proper structure' do
        result = described_class.call(course.id)

        expect(result).to be_a(Hash)
        expect(result['name']).to eq(course.id)
        expect(result['title']).to eq(course.title)
        expect(result['description']).to eq(course.description)
      end

      it 'includes all required Frappe-compatible fields' do
        result = described_class.call(course.id)

        required_fields = [
          'name', 'title', 'description', 'short_introduction', 'published',
          'upcoming', 'featured', 'disable_self_learning', 'course_price',
          'currency', 'amount_usd', 'paid_course', 'enable_certification',
          'paid_certificate', 'video_link', 'tags', 'image', 'card_gradient',
          'instructors', 'category', 'enrollments', 'enrollment_count',
          'lessons', 'rating', 'creation', 'modified', 'owner',
          'instructor', 'instructor_id', 'enrollment_count_formatted',
          'total_reviews', 'rating_distribution'
        ]

        required_fields.each do |field|
          expect(result).to have_key(field)
        end
      end

      it 'formats dates correctly' do
        result = described_class.call(course.id)

        expect(result['creation']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(result['modified']).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'includes instructor information' do
        result = described_class.call(course.id)

        expect(result['instructor']).to eq(instructor.full_name)
        expect(result['instructor_id']).to eq(instructor.id)
        expect(result['owner']).to eq(instructor.email)
        expect(result['instructors']).to be_an(Array)
        expect(result['instructors'].first).to eq(instructor.full_name)
      end
    end

    context 'with user parameter' do
      let!(:enrollment) { create(:enrollment, user: student, course: course, progress: 75) }

      it 'includes membership data for enrolled user' do
        result = described_class.call(course.id, student)

        expect(result['membership']).to be_a(Hash)
        expect(result['membership']['progress']).to eq(75)
        expect(result['membership']['completed']).to be false
      end

      it 'includes current lesson for enrolled user' do
        # Create a lesson and mark it as current
        chapter = create(:chapter, course: course)
        lesson = create(:lesson, chapter: chapter)

        result = described_class.call(course.id, student)
        expect(result).to have_key('current_lesson')
      end

      it 'returns nil membership for non-enrolled user' do
        other_user = create(:user)
        result = described_class.call(course.id, other_user)

        expect(result['membership']).to be_nil
      end
    end

    context 'with invalid course id' do
      it 'returns error for non-existent course' do
        result = described_class.call(99999)

        expect(result).to have_key('error')
        expect(result['error']).to eq('Course not found')
        expect(result['status']).to eq(404)
      end
    end

    context 'course statistics' do
      before do
        create_list(:enrollment, 3, course: course)
        create(:course_review, course: course, rating: 5, owner: student.email)
        create(:course_review, course: course, rating: 4, owner: 'other@example.com')
      end

      it 'includes accurate enrollment count' do
        result = described_class.call(course.id)

        expect(result['enrollments']).to eq(3)
        expect(result['enrollment_count']).to eq(3)
      end

      it 'includes formatted enrollment count' do
        result = described_class.call(course.id)

        expect(result['enrollment_count_formatted']).to eq('3')
      end

      it 'includes review statistics' do
        result = described_class.call(course.id)

        expect(result['total_reviews']).to eq(2)
        expect(result['rating']).to eq(4.5)
        expect(result['rating_distribution']).to be_a(Hash)
        expect(result['rating_distribution']['5']).to eq(1)
        expect(result['rating_distribution']['4']).to eq(1)
      end
    end

    context 'paid course information' do
      let(:paid_course) { create(:course, :published, instructor: instructor, course_price: 5000, currency: 'NGN') }

      it 'includes payment information for paid courses' do
        result = described_class.call(paid_course.id)

        expect(result['paid_course']).to be true
        expect(result['course_price']).to eq(5000)
        expect(result['currency']).to eq('NGN')
        expect(result['amount_usd']).to be > 0
      end
    end
  end
end
