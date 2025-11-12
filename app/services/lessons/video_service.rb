# frozen_string_literal: true

class Lessons::VideoService
  def self.track_duration(params, user)
    return { error: "User not authenticated" } unless user
    return { error: "Lesson not found" } unless params[:lesson_id]

    lesson = Lesson.find_by(id: params[:lesson_id])
    return { error: "Lesson not found" } unless lesson

    # Check if user is enrolled in the course
    unless user.enrollments.exists?(course_id: lesson.course_id)
      return { error: "User not enrolled in this course" }
    end

    # Validate duration
    duration = params[:duration].to_f
    return { error: "Invalid duration" } if duration < 0

    # Get or create video watch record
    watch_record = user.video_watch_durations.find_or_initialize_by(
      lesson: lesson
    )

    # Update watch duration
    total_duration = (watch_record.total_duration || 0) + duration
    watch_record.update!(
      total_duration: total_duration,
      last_watched_at: Time.current,
      watch_count: (watch_record.watch_count || 0) + 1
    )

    # Update lesson progress based on video watching
    lesson_duration = lesson.duration_minutes || 0
    if lesson_duration > 0
      video_progress = [ (total_duration / 60.0 / lesson_duration * 100), 100 ].min
      update_lesson_progress_from_video(lesson, user, video_progress)
    end

    {
      success: true,
      lesson_id: lesson.id,
      lesson_title: lesson.title,
      duration_watched: duration,
      total_duration: total_duration,
      video_progress: lesson_duration > 0 ? [ (total_duration / 60.0 / lesson_duration * 100), 100 ].min : 0,
      lesson_completed: total_duration >= (lesson_duration * 60),
      watch_count: watch_record.watch_count,
      last_watched_at: watch_record.last_watched_at.strftime("%Y-%m-%d %H:%M:%S")
    }
  rescue => e
    {
      error: "Failed to track video duration",
      details: e.message
    }
  end

  def self.get_video_stats(lesson_id, user)
    return { error: "User not authenticated" } unless user

    lesson = Lesson.find_by(id: lesson_id)
    return { error: "Lesson not found" } unless lesson

    watch_record = user.video_watch_durations.find_by(lesson: lesson)

    {
      success: true,
      lesson_id: lesson.id,
      lesson_title: lesson.title,
      total_duration: watch_record&.total_duration || 0,
      lesson_duration: lesson.duration_minutes || 0,
      watch_count: watch_record&.watch_count || 0,
      last_watched_at: watch_record&.last_watched_at&.strftime("%Y-%m-%d %H:%M:%S"),
      completion_percentage: lesson.duration_minutes > 0 ?
        [ (watch_record&.total_duration || 0) / 60.0 / lesson.duration_minutes * 100, 100 ].min : 0
    }
  end

  private

  def self.update_lesson_progress_from_video(lesson, user, video_progress)
    progress = LessonProgress.find_or_initialize_by(
      user: user,
      lesson: lesson
    )

    # Only update progress if video progress is higher than current progress
    if video_progress > progress.progress
      progress.update!(
        progress: video_progress,
        completed: video_progress >= 100,
        completed_at: video_progress >= 100 ? Time.current : nil,
        started_at: progress.started_at || Time.current
      )

      # Update course progress
      update_course_progress(user, lesson.course)
    end
  end

  def self.update_course_progress(user, course)
    return unless course

    total_lessons = course.lessons.count
    return if total_lessons == 0

    completed_lessons = user.lesson_progresses
                             .joins(:lesson)
                             .where(lessons: { course: course.id.to_s }, completed: true)
                             .count

    course_progress = user.course_progresses.where(course: course).first_or_create
    new_progress = (completed_lessons.to_f / total_lessons * 100).round(2)

    course_progress.update!(
      progress: new_progress,
      status: new_progress >= 80 ? "Completed" : "In Progress",
      updated_at: Time.current
    )
  end
end
