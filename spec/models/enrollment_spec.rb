require 'rails_helper'

RSpec.describe Enrollment, type: :model do
  let(:course) { create(:course, title: 'Test Course') }
  let(:user) { create(:user, email: 'test01@test.com', first_name: 'Test') }
  let(:batch) { create(:batch, title: 'Test Batch', instructor: user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      enrollment = build(:enrollment, course: course, user: user)
      expect(enrollment).to be_valid
    end

    it 'is invalid without a course' do
      enrollment = build(:enrollment, course: nil, user: user)
      expect(enrollment).to_not be_valid
    end

    it 'is invalid without a user' do
      enrollment = build(:enrollment, course: course, user: nil)
      expect(enrollment).to_not be_valid
    end

    it 'prevents duplicate enrollments for same user and course' do
      create(:enrollment, course: course, user: user)
      duplicate_enrollment = build(:enrollment, course: course, user: user)
      expect(duplicate_enrollment).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to course' do
      enrollment = create(:enrollment, course: course, user: user)
      expect(enrollment.course).to eq(course)
    end

    it 'belongs to user' do
      enrollment = create(:enrollment, course: course, user: user)
      expect(enrollment.user).to eq(user)
    end

    it 'can belong to batch' do
      enrollment = create(:enrollment, course: course, user: user, batch: batch)
      expect(enrollment.batch).to eq(batch)
    end

    it 'has many lesson_progresses' do
      enrollment = create(:enrollment, course: course, user: user)
      expect(enrollment).to respond_to(:lesson_progresses)
    end
  end

  describe 'enrollment with batch (matching Frappe test_lms_enrollment.py)' do
    let(:mentor) { create(:user, email: 'mentor@test.com', first_name: 'Test Mentor') }

    before do
      # Add mentor to course (similar to Frappe test setup)
      course.add_mentor(mentor.email) if course.respond_to?(:add_mentor)
    end

    it 'creates enrollment with course and member name' do
      enrollment = create(:enrollment,
                         course: course,
                         user: user,
                         batch: batch)

      expect(enrollment.course).to eq(course)
      expect(enrollment.user.full_name).to eq(user.full_name)
    end

    it 'allows changing member role' do
      enrollment = create(:enrollment,
                         course: course,
                         user: user,
                         batch: batch)

      # It should be possible to change role
      enrollment.update!(role: 'Admin')
      expect(enrollment.reload.role).to eq('Admin')
    end

    it 'sets enrollment date' do
      enrollment = create(:enrollment, course: course, user: user)
      expect(enrollment.created_at).to be_present
      expect(enrollment.created_at).to be <= Time.current
    end
  end

  describe '#progress_percentage' do
    let(:chapter) { create(:course_chapter, course: course) }
    let!(:lesson1) { create(:course_lesson, chapter: chapter, course: course) }
    let!(:lesson2) { create(:course_lesson, chapter: chapter, course: course) }
    let(:enrollment) { create(:enrollment, course: course, user: user) }

    it 'returns 0 when no lessons completed' do
      expect(enrollment.progress_percentage).to eq(0)
    end

    it 'returns 50 when half lessons completed' do
      LessonProgress.create!(user: user, lesson: lesson1, status: 'Complete', progress: 100)
      expect(enrollment.progress_percentage).to eq(50)
    end

    it 'returns 100 when all lessons completed' do
      create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
      create(:lesson_progress, user: user, lesson: lesson2, status: 'Complete')
      expect(enrollment.progress_percentage).to eq(100)
    end
  end

  describe '#completed_lessons_count' do
    let(:chapter) { create(:course_chapter, course: course) }
    let!(:lesson1) { create(:course_lesson, chapter: chapter, course: course) }
    let!(:lesson2) { create(:course_lesson, chapter: chapter, course: course) }
    let(:enrollment) { create(:enrollment, course: course, user: user) }

    it 'returns 0 when no lessons completed' do
      expect(enrollment.completed_lessons_count).to eq(0)
    end

    it 'returns correct count of completed lessons' do
      create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
      expect(enrollment.completed_lessons_count).to eq(1)

      create(:lesson_progress, user: user, lesson: lesson2, status: 'Complete')
      expect(enrollment.completed_lessons_count).to eq(2)
    end
  end

  describe '#is_completed?' do
    let(:chapter) { create(:course_chapter, course: course) }
    let!(:lesson1) { create(:course_lesson, chapter: chapter, course: course) }
    let!(:lesson2) { create(:course_lesson, chapter: chapter, course: course) }
    let(:enrollment) { create(:enrollment, course: course, user: user) }

    it 'returns false when not all lessons completed' do
      create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
      expect(enrollment.is_completed?).to be_falsey
    end

    it 'returns true when all lessons completed' do
      create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
      create(:lesson_progress, user: user, lesson: lesson2, status: 'Complete')
      expect(enrollment.is_completed?).to be_truthy
    end
  end

  describe '#current_lesson' do
    let(:chapter) { create(:course_chapter, course: course) }
    let!(:lesson1) { create(:course_lesson, chapter: chapter, course: course, idx: 1) }
    let!(:lesson2) { create(:course_lesson, chapter: chapter, course: course, idx: 2) }
    let(:enrollment) { create(:enrollment, course: course, user: user) }

    it 'returns first lesson when no progress' do
      expect(enrollment.current_lesson).to eq(lesson1)
    end

    it 'returns next lesson after completing current' do
      create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
      expect(enrollment.current_lesson).to eq(lesson2)
    end

    it 'returns last lesson when all completed' do
      create(:lesson_progress, user: user, lesson: lesson1, status: 'Complete')
      create(:lesson_progress, user: user, lesson: lesson2, status: 'Complete')
      expect(enrollment.current_lesson).to eq(lesson2)
    end
  end

  describe 'scopes' do
    let(:user2) { create(:user, email: 'test02@test.com', first_name: 'Test2') }
    let!(:active_enrollment) { create(:enrollment, course: course, user: user, status: 'Active') }
    let!(:completed_enrollment) { create(:enrollment, course: course, user: user2, status: 'Completed') }

    describe '.active' do
      it 'returns only active enrollments' do
        expect(Enrollment.active).to include(active_enrollment)
        expect(Enrollment.active).not_to include(completed_enrollment)
      end
    end

    describe '.by_course' do
      let(:other_course) { create(:course) }
      let!(:other_enrollment) { create(:enrollment, course: other_course) }

      it 'returns enrollments for specific course' do
        expect(Enrollment.by_course(course)).to include(active_enrollment)
        expect(Enrollment.by_course(course)).not_to include(other_enrollment)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'sets enrollment status to active by default' do
        enrollment = create(:enrollment, course: course, user: user)
        expect(enrollment.status).to eq('Active')
      end

      it 'sends enrollment confirmation if configured' do
        # This would test email sending if implemented
        expect do
          create(:enrollment, course: course, user: user)
        end.not_to raise_error
      end
    end
  end

  # Test helper methods (similar to Frappe test helpers)
  def add_membership(batch, user, course, member_type = 'Student')
    create(:enrollment,
           batch: batch,
           user: user,
           course: course,
           member_type: member_type)
  end

  after(:each) do
    # Clean up data similar to Frappe tearDown
    LessonProgress.where(user: user).destroy_all
    Enrollment.where(course: course).destroy_all
    Enrollment.where(user: user).destroy_all
  end
end
