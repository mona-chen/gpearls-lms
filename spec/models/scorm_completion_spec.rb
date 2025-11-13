require 'rails_helper'

RSpec.describe ScormCompletion, type: :model do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:chapter) { create(:course_chapter, course: course) }
  let(:lesson) { create(:course_lesson, course_chapter: chapter, course: course) }
  let(:scorm_package) { create(:scorm_package, course_lesson: lesson) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      completion = build(:scorm_completion,
                        user: user,
                        scorm_package: scorm_package,
                        course_lesson: lesson)
      expect(completion).to be_valid
    end

    it 'prevents duplicate completions for same user and package' do
      create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      duplicate = build(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      expect(duplicate).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      completion = create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      expect(completion.user).to eq(user)
    end

    it 'belongs to scorm_package' do
      completion = create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      expect(completion.scorm_package).to eq(scorm_package)
    end

    it 'belongs to course_lesson' do
      completion = create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      expect(completion.course_lesson).to eq(lesson)
    end
  end

  describe 'enums' do
    it 'defines completion_status enum' do
      completion = create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      expect(completion).to respond_to(:incomplete?)
      expect(completion).to respond_to(:completed?)
      expect(completion).to respond_to(:passed?)
      expect(completion).to respond_to(:failed?)
      expect(completion).to respond_to(:browsed?)
      expect(completion).to respond_to(:not_attempted?)
    end

    it 'defines success_status enum' do
      completion = create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson)
      expect(completion).to respond_to(:unknown?)
      expect(completion).to respond_to(:passed_success?)
      expect(completion).to respond_to(:failed_success?)
    end
  end

  describe '#progress_percentage' do
    it 'returns 100 for completed status' do
      completion = create(:scorm_completion, 
                         completion_status: :completed,
                         user: user,
                         scorm_package: scorm_package,
                         course_lesson: lesson)
      expect(completion.progress_percentage).to eq(100)
    end

    it 'returns 100 for passed status' do
      completion = create(:scorm_completion,
                         completion_status: :passed,
                         user: user,
                         scorm_package: scorm_package,
                         course_lesson: lesson)
      expect(completion.progress_percentage).to eq(100)
    end

    it 'returns 50 for failed status' do
      completion = create(:scorm_completion,
                         completion_status: :failed,
                         user: user,
                         scorm_package: scorm_package,
                         course_lesson: lesson)
      expect(completion.progress_percentage).to eq(50)
    end

    it 'returns score_raw for incomplete status' do
      completion = create(:scorm_completion,
                         completion_status: :incomplete,
                         score_raw: 75,
                         user: user,
                         scorm_package: scorm_package,
                         course_lesson: lesson)
      expect(completion.progress_percentage).to eq(75)
    end

    it 'returns 0 for not_attempted status' do
      completion = create(:scorm_completion,
                         completion_status: :not_attempted,
                         user: user,
                         scorm_package: scorm_package,
                         course_lesson: lesson)
      expect(completion.progress_percentage).to eq(0)
    end
  end

  describe '#update_from_scorm_data' do
    let(:completion) { create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson) }
    let(:scorm_data) do
      {
        'cmi.core.lesson_status' => 'completed',
        'cmi.core.score.raw' => '85',
        'cmi.core.score.min' => '0',
        'cmi.core.score.max' => '100',
        'cmi.core.total_time' => '0000:25:30.00',
        'cmi.core.session_time' => '0000:10:15.00',
        'cmi.suspend_data' => 'progress_data',
        'cmi.core.location' => 'page_5'
      }
    end

    it 'updates completion from SCORM data' do
      completion.update_from_scorm_data(scorm_data)
      completion.reload

      expect(completion.completion_status).to eq('completed')
      expect(completion.score_raw).to eq(85.0)
      expect(completion.score_min).to eq(0.0)
      expect(completion.score_max).to eq(100.0)
      expect(completion.total_time).to eq(1530) # 25:30 in seconds
      expect(completion.session_time).to eq(615) # 10:15 in seconds
      expect(completion.suspend_data).to eq('progress_data')
      expect(completion.location).to eq('page_5')
      expect(completion.last_accessed_at).to be_present
    end

    it 'parses SCORM time format correctly' do
      scorm_data = { 'cmi.core.total_time' => '0001:23:45.00' }
      completion.update_from_scorm_data(scorm_data)
      
      # 1 hour 23 minutes 45 seconds = 3600 + 1380 + 45 = 5025 seconds
      expect(completion.total_time).to eq(5025)
    end

    it 'handles ISO 8601 duration format' do
      scorm_data = { 'cmi.core.total_time' => 'PT1H23M45S' }
      completion.update_from_scorm_data(scorm_data)
      
      # 1 hour 23 minutes 45 seconds = 5025 seconds
      expect(completion.total_time).to eq(5025)
    end

    it 'updates lesson progress when completed' do
      allow(completion).to receive(:update_lesson_progress)
      
      scorm_data = { 'cmi.core.lesson_status' => 'completed' }
      completion.update_from_scorm_data(scorm_data)
      
      expect(completion).to have_received(:update_lesson_progress)
    end
  end

  describe '#completed_or_passed?' do
    it 'returns true for completed status' do
      completion = create(:scorm_completion, completion_status: :completed)
      expect(completion.completed_or_passed?).to be_truthy
    end

    it 'returns true for passed status' do
      completion = create(:scorm_completion, completion_status: :passed)
      expect(completion.completed_or_passed?).to be_truthy
    end

    it 'returns false for incomplete status' do
      completion = create(:scorm_completion, completion_status: :incomplete)
      expect(completion.completed_or_passed?).to be_falsey
    end
  end

  describe '.track_scorm_interaction' do
    let(:scorm_data) do
      {
        'cmi.core.lesson_status' => 'incomplete',
        'cmi.core.score.raw' => '50'
      }
    end

    it 'creates new completion record' do
      expect do
        ScormCompletion.track_scorm_interaction(user, scorm_package, lesson, scorm_data)
      end.to change(ScormCompletion, :count).by(1)

      completion = ScormCompletion.last
      expect(completion.user).to eq(user)
      expect(completion.scorm_package).to eq(scorm_package)
      expect(completion.course_lesson).to eq(lesson)
      expect(completion.started_at).to be_present
    end

    it 'updates existing completion record' do
      existing = create(:scorm_completion, 
                       user: user, 
                       scorm_package: scorm_package, 
                       course_lesson: lesson,
                       completion_status: :not_attempted)

      ScormCompletion.track_scorm_interaction(user, scorm_package, lesson, scorm_data)
      existing.reload

      expect(existing.completion_status).to eq('incomplete')
      expect(existing.score_raw).to eq(50.0)
    end
  end

  describe '.get_analytics_for_package' do
    before do
      # Create multiple completions with different statuses
      create(:scorm_completion,
             scorm_package: scorm_package,
             completion_status: :completed,
             score_raw: 85,
             total_time: 1800)

      create(:scorm_completion,
             scorm_package: scorm_package,
             completion_status: :passed,
             score_raw: 95,
             total_time: 1200)

      create(:scorm_completion,
             scorm_package: scorm_package,
             completion_status: :incomplete,
             score_raw: 60,
             total_time: 900)
    end

    it 'calculates package analytics correctly' do
      analytics = ScormCompletion.get_analytics_for_package(scorm_package)

      expect(analytics[:total_attempts]).to eq(3)
      expect(analytics[:completed_count]).to eq(2) # completed + passed
      expect(analytics[:average_score]).to eq(80.0) # (85 + 95 + 60) / 3
      expect(analytics[:completion_rate]).to eq(66.67) # 2/3 * 100, rounded
      expect(analytics[:average_time_spent]).to eq(1300.0) # (1800 + 1200 + 900) / 3
      
      expect(analytics[:status_distribution]).to include(
        'completed' => 1,
        'passed' => 1,
        'incomplete' => 1
      )
    end
  end

  describe 'scopes' do
    let(:other_lesson) { create(:course_lesson) }
    let(:other_package) { create(:scorm_package, course_lesson: other_lesson) }

    before do
      create(:scorm_completion, course_lesson: lesson, scorm_package: scorm_package, completion_status: :completed)
      create(:scorm_completion, course_lesson: other_lesson, scorm_package: other_package, completion_status: :incomplete)
      create(:scorm_completion, course_lesson: lesson, scorm_package: scorm_package, completion_status: :passed)
    end

    describe '.by_lesson' do
      it 'returns completions for specific lesson' do
        completions = ScormCompletion.by_lesson(lesson)
        expect(completions.count).to eq(2)
        expect(completions.pluck(:course_lesson_id)).to all(eq(lesson.id))
      end
    end

    describe '.by_package' do
      it 'returns completions for specific package' do
        completions = ScormCompletion.by_package(scorm_package)
        expect(completions.count).to eq(2)
        expect(completions.pluck(:scorm_package_id)).to all(eq(scorm_package.id))
      end
    end

    describe '.completed_users' do
      it 'returns only completed or passed completions' do
        completions = ScormCompletion.completed_users
        expect(completions.count).to eq(2)
        expect(completions.map(&:completion_status)).to contain_exactly('completed', 'passed')
      end
    end
  end

  describe 'SCORM data mapping' do
    let(:completion) { create(:scorm_completion, user: user, scorm_package: scorm_package, course_lesson: lesson) }

    it 'maps SCORM lesson status to completion status' do
      expect(completion.send(:map_completion_status, 'completed')).to eq(:completed)
      expect(completion.send(:map_completion_status, 'incomplete')).to eq(:incomplete)
      expect(completion.send(:map_completion_status, 'passed')).to eq(:passed)
      expect(completion.send(:map_completion_status, 'failed')).to eq(:failed)
      expect(completion.send(:map_completion_status, 'browsed')).to eq(:browsed)
      expect(completion.send(:map_completion_status, 'unknown')).to eq(:not_attempted)
    end

    it 'maps SCORM success status' do
      expect(completion.send(:map_success_status, 'passed')).to eq(:passed_success)
      expect(completion.send(:map_success_status, 'failed')).to eq(:failed_success)
      expect(completion.send(:map_success_status, 'unknown')).to eq(:unknown)
    end
  end
end