require 'rails_helper'

RSpec.describe VideoWatchDuration, type: :model do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:chapter) { create(:course_chapter, course: course) }
  let(:lesson) { create(:course_lesson, chapter: chapter, course: course) }
  let(:video_url) { 'https://example.com/video.mp4' }

  describe 'validations' do
    it 'is valid with valid attributes' do
      duration = build(:video_watch_duration,
                      user: user,
                      course_lesson: lesson,
                      video_url: video_url,
                      duration_watched: 120,
                      video_length: 300)
      expect(duration).to be_valid
    end

    it 'is invalid without video_url' do
      duration = build(:video_watch_duration, video_url: nil)
      expect(duration).to_not be_valid
    end

    it 'is invalid with negative duration_watched' do
      duration = build(:video_watch_duration, duration_watched: -1)
      expect(duration).to_not be_valid
    end

    it 'is invalid with zero video_length' do
      duration = build(:video_watch_duration, video_length: 0)
      expect(duration).to_not be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      duration = create(:video_watch_duration, user: user, course_lesson: lesson)
      expect(duration.user).to eq(user)
    end

    it 'belongs to course_lesson' do
      duration = create(:video_watch_duration, user: user, course_lesson: lesson)
      expect(duration.course_lesson).to eq(lesson)
    end
  end

  describe '#progress_percentage' do
    it 'calculates correct percentage' do
      duration = create(:video_watch_duration,
                       user: user,
                       course_lesson: lesson,
                       duration_watched: 150,
                       video_length: 300)
      expect(duration.progress_percentage).to eq(50.0)
    end

    it 'caps at 100%' do
      duration = create(:video_watch_duration,
                       user: user,
                       course_lesson: lesson,
                       duration_watched: 400,
                       video_length: 300)
      expect(duration.progress_percentage).to eq(100.0)
    end

    it 'returns 0 for zero video length' do
      duration = build(:video_watch_duration, duration_watched: 100, video_length: 0)
      # This should be handled gracefully
      expect(duration.progress_percentage).to eq(0)
    end
  end

  describe '#completed?' do
    it 'returns true when 90% or more watched' do
      duration = create(:video_watch_duration,
                       duration_watched: 270,
                       video_length: 300)
      expect(duration.completed?).to be_truthy
    end

    it 'returns false when less than 90% watched' do
      duration = create(:video_watch_duration,
                       duration_watched: 250,
                       video_length: 300)
      expect(duration.completed?).to be_falsey
    end
  end

  describe '.track_duration' do
    it 'creates new record for first tracking' do
      expect do
        VideoWatchDuration.track_duration(user, lesson, video_url, 120, 300)
      end.to change(VideoWatchDuration, :count).by(1)

      duration = VideoWatchDuration.last
      expect(duration.user).to eq(user)
      expect(duration.course_lesson).to eq(lesson)
      expect(duration.video_url).to eq(video_url)
      expect(duration.duration_watched).to eq(120)
      expect(duration.video_length).to eq(300)
    end

    it 'updates existing record with maximum duration' do
      existing = create(:video_watch_duration,
                       user: user,
                       course_lesson: lesson,
                       video_url: video_url,
                       duration_watched: 100,
                       video_length: 300)

      VideoWatchDuration.track_duration(user, lesson, video_url, 150, 300)
      existing.reload
      expect(existing.duration_watched).to eq(150)
    end

    it 'does not decrease duration if new value is less' do
      existing = create(:video_watch_duration,
                       user: user,
                       course_lesson: lesson,
                       video_url: video_url,
                       duration_watched: 200,
                       video_length: 300)

      VideoWatchDuration.track_duration(user, lesson, video_url, 150, 300)
      existing.reload
      expect(existing.duration_watched).to eq(200)
    end

    it 'updates last_position with current duration' do
      duration = VideoWatchDuration.track_duration(user, lesson, video_url, 150, 300)
      expect(duration.last_position).to eq(150)
    end
  end

  describe '.get_analytics_for_lesson' do
    before do
      # Create multiple watch durations for the lesson
      create(:video_watch_duration,
             course_lesson: lesson,
             video_url: video_url,
             duration_watched: 270,
             video_length: 300) # 90% - completed

      create(:video_watch_duration,
             course_lesson: lesson,
             video_url: video_url,
             duration_watched: 150,
             video_length: 300) # 50% - not completed

      create(:video_watch_duration,
             course_lesson: lesson,
             video_url: video_url,
             duration_watched: 300,
             video_length: 300) # 100% - completed
    end

    it 'calculates correct analytics' do
      analytics = VideoWatchDuration.get_analytics_for_lesson(lesson)

      expect(analytics[:total_views]).to eq(3)
      expect(analytics[:unique_viewers]).to eq(3)
      expect(analytics[:average_completion]).to eq(240.0) # (270 + 150 + 300) / 3
      expect(analytics[:completion_rate]).to eq(66.67) # 2 out of 3 completed (rounded)
      expect(analytics[:total_watch_time]).to eq(720) # 270 + 150 + 300
    end
  end

  describe 'scopes' do
    let(:other_lesson) { create(:course_lesson) }
    let(:other_user) { create(:user) }

    before do
      create(:video_watch_duration, course_lesson: lesson, user: user)
      create(:video_watch_duration, course_lesson: other_lesson, user: user)
      create(:video_watch_duration, course_lesson: lesson, user: other_user)
    end

    describe '.by_lesson' do
      it 'returns durations for specific lesson' do
        durations = VideoWatchDuration.by_lesson(lesson)
        expect(durations.count).to eq(2)
        expect(durations.pluck(:course_lesson_id)).to all(eq(lesson.id))
      end
    end

    describe '.by_user' do
      it 'returns durations for specific user' do
        durations = VideoWatchDuration.by_user(user)
        expect(durations.count).to eq(2)
        expect(durations.pluck(:user_id)).to all(eq(user.id))
      end
    end

    describe '.recent' do
      it 'orders by updated_at desc' do
        durations = VideoWatchDuration.recent
        expect(durations.first.updated_at).to be >= durations.last.updated_at
      end
    end
  end

  describe 'watch session tracking' do
    it 'tracks first watch time' do
      duration = create(:video_watch_duration, user: user, course_lesson: lesson)
      expect(duration.first_watched_at).to be_present
    end

    it 'updates last watched time on save' do
      duration = create(:video_watch_duration, user: user, course_lesson: lesson)
      original_time = duration.last_watched_at

      sleep 0.1 # Ensure time difference
      duration.update!(duration_watched: duration.duration_watched + 10)

      expect(duration.last_watched_at).to be > original_time
    end
  end
end
