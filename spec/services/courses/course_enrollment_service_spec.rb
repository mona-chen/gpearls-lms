# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Courses::CourseEnrollmentService, type: :service do
  let(:instructor) { create(:user, :instructor) }
  let(:student) { create(:user) }
  let(:course) { create(:course, :published, instructor: instructor) }

  describe '.enroll' do
    context 'with valid user and course' do
      it 'creates enrollment successfully' do
        result = described_class.enroll(student, course)

        expect(result[:success]).to be true
        expect(result[:enrollment]).to be_a(Hash)
        expect(result[:message]).to eq('Successfully enrolled in course')
      end

      it 'returns Frappe-compatible enrollment data' do
        result = described_class.enroll(student, course)

        enrollment_data = result[:enrollment]
        expect(enrollment_data['name']).to be_a(String)
        expect(enrollment_data['course']).to eq(course.title)
        expect(enrollment_data['member']).to eq(student.email)
        expect(enrollment_data['progress']).to eq(0)
        expect(enrollment_data['status']).to eq('In Progress')
      end

      it 'creates enrollment record in database' do
        expect {
          described_class.enroll(student, course)
        }.to change(Enrollment, :count).by(1)

        enrollment = Enrollment.last
        expect(enrollment.user).to eq(student)
        expect(enrollment.course).to eq(course)
        expect(enrollment.progress).to eq(0)
      end

      it 'prevents duplicate enrollment' do
        described_class.enroll(student, course)

        result = described_class.enroll(student, course)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Already enrolled in this course')
      end
    end

    context 'with invalid parameters' do
      it 'returns error for nil user' do
        result = described_class.enroll(nil, course)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('User not authenticated')
      end

      it 'returns error for nil course' do
        result = described_class.enroll(student, nil)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Course not found')
      end

      it 'returns error for unpublished course' do
        draft_course = create(:course, published: false, instructor: instructor)

        result = described_class.enroll(student, draft_course)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Course not available for enrollment')
      end

      it 'returns error for upcoming course' do
        upcoming_course = create(:course, :published, upcoming: true, instructor: instructor)

        result = described_class.enroll(student, upcoming_course)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Course not available for enrollment')
      end
    end
  end

  describe '.unenroll' do
    let!(:enrollment) { create(:enrollment, user: student, course: course) }

    it 'removes enrollment successfully' do
      result = described_class.unenroll(student, course)

      expect(result[:success]).to be true
      expect(result[:message]).to eq('Successfully unenrolled from course')
    end

    it 'deletes enrollment record from database' do
      expect {
        described_class.unenroll(student, course)
      }.to change(Enrollment, :count).by(-1)
    end

    it 'returns error for non-enrolled user' do
      other_student = create(:user)

      result = described_class.unenroll(other_student, course)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Not enrolled in this course')
    end

    it 'returns error for nil user' do
      result = described_class.unenroll(nil, course)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('User not authenticated')
    end
  end

  describe '.can_enroll?' do
    it 'returns true for published course and valid user' do
      result = described_class.can_enroll?(student, course)

      expect(result).to be true
    end

    it 'returns false for unpublished course' do
      draft_course = create(:course, published: false, instructor: instructor)

      result = described_class.can_enroll?(student, draft_course)

      expect(result).to be false
    end

    it 'returns false for upcoming course' do
      upcoming_course = create(:course, :published, upcoming: true, instructor: instructor)

      result = described_class.can_enroll?(student, upcoming_course)

      expect(result).to be false
    end

    it 'returns false for already enrolled user' do
      create(:enrollment, user: student, course: course)

      result = described_class.can_enroll?(student, course)

      expect(result).to be false
    end

    it 'returns false for nil user' do
      result = described_class.can_enroll?(nil, course)

      expect(result).to be false
    end

    it 'returns false for nil course' do
      result = described_class.can_enroll?(student, nil)

      expect(result).to be false
    end
  end
end
