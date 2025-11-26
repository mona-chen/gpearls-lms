class VideoWatchDuration < ApplicationRecord
  belongs_to :user
  belongs_to :course_lesson

   validates :video_url, presence: true
   validates :duration_watched, presence: true, numericality: { greater_than: 0 }
   validates :video_length, presence: true, numericality: { greater_than: 0 }

   scope :by_lesson, ->(lesson) { where(course_lesson: lesson) }
   scope :by_user, ->(user) { where(user: user) }
   scope :recent, -> { order(updated_at: :desc) }

   before_create :set_first_watched_at
   before_save :update_last_watched_at

  def progress_percentage
    return 0 if video_length.zero?
    [ (duration_watched.to_f / video_length * 100).round(2), 100 ].min
  end

  def completed?
    progress_percentage >= 90 # Consider 90%+ as completed
  end

  def self.track_duration(user, lesson, video_url, duration_watched, video_length)
    existing = find_by(user: user, course_lesson: lesson, video_url: video_url)

    if existing
      # Update with maximum duration watched
      if duration_watched > existing.duration_watched
        existing.update!(
          duration_watched: duration_watched,
          video_length: video_length,
          last_position: duration_watched
        )
      end
      existing
    else
      create!(
        user: user,
        course_lesson: lesson,
        video_url: video_url,
        duration_watched: duration_watched,
        video_length: video_length,
        last_position: duration_watched
      )
    end
  end

  def self.get_analytics_for_lesson(lesson)
    durations = where(course_lesson: lesson)

    {
      total_views: durations.count,
      unique_viewers: durations.distinct.count(:user_id),
      average_completion: durations.average(:duration_watched) || 0,
      completion_rate: (durations.where("duration_watched >= video_length * 0.9").count.to_f / durations.count * 100).round(2),
      total_watch_time: durations.sum(:duration_watched)
    }
  end

   private

   def set_first_watched_at
     self.first_watched_at ||= Time.current
   end

   def update_last_watched_at
     self.last_watched_at = Time.current
   end
end
