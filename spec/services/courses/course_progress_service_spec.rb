# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Courses::CourseProgressService, type: :service do
  let(:instructor) { create(:user, :instructor) }
  let(:student) { create(:user) }
  let(:course) { create(:course, :published, instructor: instructor) }
  let(:chapter) { create(:chapter, course: course) }
  let(:lesson) { create(:lesson, chapter: chapter, course: course) }
  let!(:enrollment) { create(:enrollment, user: student, course: course) }

  describe '.update_progress' do
    context 'with valid parameters' do
      it 'marks lesson as complete' do
        result = described_class.update_progress(student, course, lesson, true)

        expect(result[:success]).to be true
        expect(result[:progress]).to eq('Complete')
        expect(result[:message]).to eq('Lesson completed')
      end

      it 'marks lesson as incomplete' do
        result = described_class.update_progress(student, course, lesson, false)

        expect(result[:success]).to be true
        expect(result[:progress]).to eq('Incomplete')
        expect(result[:message]).to eq('Lesson marked incomplete')
      end

      it 'creates course progress record' do
        expect {
          described_class.update_progress(student, course, lesson, true)
        }.to change(CourseProgress, :count).by(1)

        progress = CourseProgress.last
        expect(progress.member).to eq(student.email)
        expect(progress.course).to eq(course.name)
        expect(progress.lesson).to eq(lesson.name)
        expect(progress.status).to eq('Complete')
      end

      it 'updates existing progress record' do
        described_class.update_progress(student, course, lesson, true)

        result = described_class.update_progress(student, course, lesson, false)

        expect(result[:success]).to be true
        expect(result[:progress]).to eq('Incomplete')

        progress = CourseProgress.last
        expect(progress.status).to eq('Incomplete')
      end

      it 'returns course progress percentage' do
        result = described_class.update_progress(student, course, lesson, true)

        expect(result[:course_progress]).to eq(100.0)
      end
    end

    context 'with invalid parameters' do
      it 'returns error for nil user' do
        result = described_class.update_progress(nil, course, lesson, true)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('User not authenticated')
      end

      it 'returns error for nil course' do
        result = described_class.update_progress(student, nil, lesson, true)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Course not found')
      end

      it 'returns error for nil lesson' do
        result = described_class.update_progress(student, course, nil, true)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Lesson not found')
      end

      it 'returns error for unenrolled user' do
        other_student = create(:user)

        result = described_class.update_progress(other_student, course, lesson, true)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Not enrolled in this course')
      end
    end

    context 'enrollment progress updates' do
      let!(:lesson2) { create(:lesson, chapter: chapter) }

      it 'updates enrollment progress when lesson completed' do
        described_class.update_progress(student, course, lesson, true)

        enrollment.reload
        expect(enrollment.progress).to eq(50.0) # 1 out of 2 lessons completed
      end

      it 'marks enrollment as completed when all lessons done' do
        described_class.update_progress(student, course, lesson, true)
        described_class.update_progress(student, course, lesson2, true)

        enrollment.reload
        expect(enrollment.progress).to eq(100.0)
        expect(enrollment.completed?).to be true
      end
    end
  end

  describe '.get_progress' do
    context 'with valid parameters' do
      it 'returns course progress information' do
        result = described_class.get_progress(student, course)

        expect(result[:success]).to be true
        expect(result[:course]).to eq(course.name)
        expect(result[:total_lessons]).to eq(1)
        expect(result[:completed_lessons]).to eq(0)
        expect(result[:progress]).to eq(0.0)
        expect(result[:status]).to eq("Not Started")
      end

      it 'calculates progress correctly with completed lessons' do
        described_class.update_progress(student, course, lesson, true)

        result = described_class.get_progress(student, course)

        expect(result[:completed_lessons]).to eq(1)
        expect(result[:progress]).to eq(100.0)
        expect(result[:status]).to eq('Completed')
      end

      it 'returns partial progress for in-progress courses' do
        lesson2 = create(:lesson, chapter: chapter)
        described_class.update_progress(student, course, lesson, true)

        result = described_class.get_progress(student, course)

        expect(result[:total_lessons]).to eq(2)
        expect(result[:completed_lessons]).to eq(1)
        expect(result[:progress]).to eq(50.0)
        expect(result[:status]).to eq('In Progress')
      end
    end

    context 'with invalid parameters' do
      it 'returns error for nil user' do
        result = described_class.get_progress(nil, course)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('User not authenticated')
      end

      it 'returns error for nil course' do
        result = described_class.get_progress(student, nil)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Course not found')
      end
    end

    context 'edge cases' do
      it 'handles courses with no lessons' do
        course_without_lessons = create(:course, :published, instructor: instructor)
        create(:enrollment, user: student, course: course_without_lessons)

        result = described_class.get_progress(student, course_without_lessons)

        expect(result[:total_lessons]).to eq(0)
        expect(result[:progress]).to eq(0.0)
      end
    end
  end

  describe '.save_current_lesson' do
    it 'returns success for valid parameters' do
      result = described_class.save_current_lesson(student, course, lesson)

      expect(result[:success]).to be true
      expect(result[:message]).to eq('Current lesson saved')
    end

    it 'returns error for nil user' do
      result = described_class.save_current_lesson(nil, course, lesson)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('User not authenticated')
    end

    it 'returns error for nil course' do
      result = described_class.save_current_lesson(student, nil, lesson)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Course not found')
    end

    it 'returns error for nil lesson' do
      result = described_class.save_current_lesson(student, course, nil)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Lesson not found')
    end
  end
end
